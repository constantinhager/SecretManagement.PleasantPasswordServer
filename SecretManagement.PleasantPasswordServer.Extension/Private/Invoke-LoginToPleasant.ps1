function Invoke-LoginToPleasant
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

           Invoke-LoginToPleasant -AdditionalParameters $var

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

    # Check if a login token already exists and is not expired
    $LoginToken = Get-SecretFile -LoginToken
    
    if ($null -ne $LoginToken){
        if ((get-date) -lt $loginToken.expires){
            Write-Verbose "Login token is not expired"
            return $loginToken.access_token
        } else {
            Write-Verbose "Login token is expired"
        }
    }

    # Get a token if none already exists or it is expired
    Write-Verbose "Generating new login token"
    
    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

    $SecretFile = Get-SecretFile -VaultCredential

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
    Write-Verbose $Splat.uri
    $JSON = Invoke-WebRequest @splat

    if ($null -eq $JSON)
    {
        return $null
    }
    else
    {
        # Generate and store JSON token
        $token = ConvertFrom-Json $JSON.Content

        $loginToken = [PSCustomObject]@{
            access_token = $token.access_token
            expires      = (Get-Date).AddSeconds($token.expires_in)
        }

        Out-SecretFile -LoginToken $loginToken

        return $loginToken.access_token
    }

}