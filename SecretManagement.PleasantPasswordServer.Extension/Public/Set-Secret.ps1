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

    $Token = Invoke-LoginToPleasant -AdditionalParameters $AdditionalParameters
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