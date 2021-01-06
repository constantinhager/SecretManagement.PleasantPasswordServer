using namespace Microsoft.PowerShell.SecretManagement

function GetSecretFile
{
    $FilePath = Join-Path -Path $env:TEMP -ChildPath "PleasantCred.xml"

    if (Test-Path -Path $FilePath)
    {
        $Credential = Import-Clixml -Path $FilePath
        return $Credential
    }
    else
    {
        throw "Credential File not found. Please import the module and run New-PleasantCredential to create the file."
    }
}

function InvokeLoginToPleasant
{

    <#
        .SYNOPSIS
         Login to Pleasant Password Server

        .DESCRIPTION
         Login to Pleasant Password Server

        .PARAMETER AdditionalParameters
         The following values need to be in there:
           ServerURL
           Port
           Login as PSCredential Object

        .EXAMPLE
           $Password = ConvertTo-SecureString -String "xxx" -AsPlainText -Force
           $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "xxx", $Password

           $var = @{
              ServerURL = "https://ppsdc1.pps.net"
              Port      = "10001"
              Login     = $Cred
           }

           InvokeLoginToPleasant -AdditionalParameters $var

        .NOTES
           Author: Constantin Hager
           Date: 2020-12-31
    #>



    [CmdletBinding()]
    param (
        [Parameter()]
        [Hashtable]
        $AdditionalParameters = (Get-SecretVault | Where-Object { $_.ModuleName -eq "SecretManagement.PleasantPasswordServer" }).VaultParameters
    )

    #$ServerURL = DecryptParameter -Parameter $AdditionalParameters.ServerURL
    #$Port = DecryptParameter -Parameter $AdditionalParameters.Port

    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

    $SecretFile = GetSecretFile

    # Create OAuth2 token params
    $tokenParams = @{
        grant_type = 'password';
        username   = $SecretFile.UserName;
        password   = $SecretFile.GetNetworkCredential().password;
    }

    # Authenticate to Pleasant Password Server
    $JSON = Invoke-WebRequest -Uri "$PasswordServerURL/OAuth2/Token" -Method POST -Body $tokenParams -ContentType "application/x-www-form-urlencoded" -ErrorAction SilentlyContinue

    if ($null -eq $JSON)
    {
        return $null
    }
    else
    {
        # Generate JSON token
        $Token = (ConvertFrom-Json $JSON.Content).access_token

        return $Token
    }

}

function Get-Secret
{
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string]
        $VaultName,

        [Parameter()]
        [hashtable]
        $AdditionalParameters = (Get-SecretVault | Where-Object { $_.ModuleName -eq "SecretManagement.PleasantPasswordServer" }).VaultParameters
    )

    $Token = InvokeLoginToPleasant -AdditionalParameters $AdditionalParameters

    if ($null -eq $Token)
    {
        throw "No token received."
    }

    $headers = @{
        "Accept"        = "application/json"
        "Authorization" = "$Token"
    }

    $body = @{
        "search" = "$Name"
    }

    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

    $Secrets = Invoke-RestMethod -method post -Uri "$PasswordServerURL/api/v5/rest/search" -body (ConvertTo-Json $body) -Headers $headers -ContentType 'application/json'
    $id = $Secrets.Credentials.id

    if ($id.Count -gt 1)
    {
        throw "Multiple ambiguous entries found for $Name, please remove the duplicate entry"
    }

    if ($null -eq $id)
    {
        throw "No secret with $Name is found"
    }

    $Credential = Invoke-RestMethod -Method get -Uri "$PasswordServerURL/api/v5/rest/credential/$id" -Headers $headers -ContentType 'application/json'
    $Password = Invoke-RestMethod -method post -Uri "$PasswordServerURL/api/v5/rest/credential/$id/password" -body (ConvertTo-Json $body) -Headers $headers -ContentType 'application/json'

    $PasswordAsSecureString = ConvertTo-SecureString -String $Password -AsPlainText -Force
    return [PSCredential]::new($Credential.Username, $PasswordAsSecureString)
}

function Set-Secret
{
    param (

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [object]
        $Secret,

        [Parameter(Mandatory)]
        [string]
        $VaultName,

        [Parameter(Mandatory)]
        [hashtable]
        $AdditionalParameters
    )

    $Token = InvokeLoginToPleasant -AdditionalParameters $AdditionalParameters
    $headers = @{
        "Accept"        = "application/json"
        "Authorization" = "$Token"
    }

    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

    $RootFolderid = Invoke-RestMethod -Uri "$PasswordServerURL/api/v5/rest/folders/root" -Headers $headers -ContentType 'application/json'

    $body_add = [ordered]@{
        "CustomUserFields"        = @{}
        "CustomApplicationFields" = @{}
        "Tags"                    = @()
        "Name"                    = $Name
        "UserName"                = $Secret.UserName
        "Password"                = $Secret.GetNetworkCredential().Password
        "Url"                     = ""
        "Notes"                   = ""
        "GroupId"                 = $RootFolderid
        "Expires"                 = $null
    }

    $splat = @{
        Uri             = "$PasswordServerURL/api/v5/rest/entries/"
        Method          = 'POST'
        Body            = (ConvertTo-Json $body_add)
        Headers         = $headers
        ContentType     = 'application/json'
        UseBasicParsing = $true
    }

    $Response = Invoke-WebRequest @splat

    if ($Response.StatusCode -eq 200)
    {
        return $true
    }
    else
    {
        return $false
    }
}

function Remove-Secret
{
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string]
        $VaultName,

        [Parameter(Mandatory)]
        [ValidateSet('Archive', 'Delete')]
        [string]
        $Action,

        [Parameter(Mandatory)]
        [string]
        $Comment,

        [Parameter()]
        [hashtable]
        $AdditionalParameters
    )

    $Token = InvokeLoginToPleasant -AdditionalParameters $AdditionalParameters
    $headers = @{
        "Accept"        = "application/json"
        "Authorization" = "$Token"
    }

    $body_search = @{
        "search" = "$Name"
    }

    $body_delete = [ordered]@{
        "Action"  = "$Action"
        "Comment" = "$Comment"
    }

    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

    $Secrets = Invoke-RestMethod -method post -Uri "$PasswordServerURL/api/v5/rest/search" -body (ConvertTo-Json $body_search) -Headers $headers -ContentType 'application/json'
    $id = $Secrets.Credentials.id

    if ($id.Count -gt 1)
    {
        throw "Multiple ambiguous entries found for $Name, please remove the duplicate entry"
    }

    if ($null -eq $id)
    {
        throw "No secret with $Name is found"
    }

    $splat = @{
        Uri             = "$PasswordServerURL/api/v5/rest/entries/$id"
        Method          = 'Delete'
        Body            = (ConvertTo-Json $body_delete)
        Headers         = $headers
        ContentType     = 'application/json'
        UseBasicParsing = $true
    }

    $Response = Invoke-WebRequest @splat

    if ($Response.StatusCode -eq 204)
    {
        return $true
    }
    else
    {
        return $false
    }
}

function Get-SecretInfo
{
    param (
        [Parameter(Mandatory)]
        [string]
        $VaultName,

        [Parameter()]
        [string]
        $Filter,

        [Parameter()]
        [hashtable]
        $AdditionalParameters
    )

    $Token = InvokeLoginToPleasant -AdditionalParameters $AdditionalParameters
    $headers = @{
        "Accept"        = "application/json"
        "Authorization" = "$Token"
    }

    $body = @{
        "search" = "$Filter"
    }

    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

    $Secrets = Invoke-RestMethod -method post -Uri "$PasswordServerURL/api/v5/rest/search" -body (ConvertTo-Json $body) -Headers $headers -ContentType 'application/json'
    $id = $Secrets.Credentials.id

    if ($id.Count -gt 1)
    {
        throw "Multiple ambiguous entries found for $Name, please remove the duplicate entry"
    }

    if ($null -eq $id)
    {
        throw "No secret with $Name is found"
    }

    return [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
        $Filter,
        [SecretType]::PSCredential,
        $VaultName
    )
}

function Test-SecretVault
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $VaultName,

        [Parameter()]
        [hashtable]
        $AdditionalParameters
    )

    $Parameters = @{
        ServerURL = $AdditionalParameters.ServerURL
        Port      = $AdditionalParameters.Port
    }

    $Token = InvokeLoginToPleasant -AdditionalParameters $Parameters

    if ($null -eq $Token)
    {
        return $false
    }
    else
    {
        return $true
    }
}