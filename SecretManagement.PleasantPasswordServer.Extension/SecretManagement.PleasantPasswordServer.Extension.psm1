using namespace Microsoft.PowerShell.SecretManagement

function Write-VaultError
{
    param
    (
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    <#
    .SYNOPSIS
    Takes a terminating error and first writes it as a non-terminating error to the user to better surface the issue.
    .NOTES
    This was taken from Justin Grote and his Keepass extension https://github.com/JustinGrote/SecretManagement.KeePass
    #>

    $lastErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    Write-Error -Message "Vault ${VaultName}: $($ErrorRecord.Exception.Message)"
    $ErrorActionPreference = $lastErrorActionPreference
    throw $ErrorRecord
}


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

        .EXAMPLE

           $var = @{
              ServerURL = "https://ppsdc1.pps.net"
              Port      = "10001"
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
        $AdditionalParameters
    )

    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

    $SecretFile = GetSecretFile

    # Create OAuth2 token params
    $tokenParams = @{
        grant_type = 'password';
        username   = $SecretFile.UserName;
        password   = $SecretFile.GetNetworkCredential().password;
    }

    $splat = @{
        Uri         = "$PasswordServerURL/OAuth2/Token"
        Method      = "POST"
        Body        = $tokenParams
        ContentType = "application/x-www-form-urlencoded"
        ErrorAction = "SilentlyContinue"
    }

    # Authenticate to Pleasant Password Server
    $JSON = Invoke-WebRequest @splat

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
        $AdditionalParameters
    )

    trap
    {
        Write-VaultError -ErrorRecord $_
    }

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

    if ([string]::IsNullOrWhiteSpace($Password))
    {
        $PasswordAsSecureString = ConvertTo-SecureString -String " " -AsPlainText -Force
    }
    else
    {
        $PasswordAsSecureString = ConvertTo-SecureString -String $Password -AsPlainText -Force
    }

    if ([string]::IsNullOrWhiteSpace($Credential.UserName))
    {
        $UserName = "notneeded"
    }
    else
    {
        $UserName = $Credential.Username
    }

    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $PasswordAsSecureString

    return $Credential
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

    trap
    {
        Write-VaultError -ErrorRecord $_
    }

    $Token = InvokeLoginToPleasant -AdditionalParameters $AdditionalParameters
    $headers = @{
        "Accept"        = "application/json"
        "Authorization" = "$Token"
    }

    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

    $RootFolderid = Invoke-RestMethod -Uri "$PasswordServerURL/api/v5/rest/folders/root" -Headers $headers -ContentType 'application/json'


    if ($Secret -is [System.Management.Automation.PSCredential])
    {
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
    }

    if ($Secret -is [System.Security.SecureString])
    {
        $body_add = [ordered]@{
            "CustomUserFields"        = @{}
            "CustomApplicationFields" = @{}
            "Tags"                    = @()
            "Name"                    = $Name
            "UserName"                = ""
            "Password"                = ConvertFrom-SecureString -SecureString $Secret
            "Url"                     = ""
            "Notes"                   = ""
            "GroupId"                 = $RootFolderid
            "Expires"                 = $null
        }
    }

    if ($null -eq $body_add)
    {
        return $false
    }
    else
    {
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

        [Parameter()]
        [hashtable]
        $AdditionalParameters
    )

    trap
    {
        Write-VaultError -ErrorRecord $_
    }

    $Token = InvokeLoginToPleasant -AdditionalParameters $AdditionalParameters
    $headers = @{
        "Accept"        = "application/json"
        "Authorization" = "$Token"
    }

    $body_search = @{
        "search" = "$Name"
    }

    $body_delete = [ordered]@{
        "Action"  = "Delete"
        "Comment" = "Deleted through SecretsManagement"
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

    trap
    {
        Write-VaultError -ErrorRecord $_
    }

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

    trap
    {
        Write-VaultError -ErrorRecord $_
    }

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