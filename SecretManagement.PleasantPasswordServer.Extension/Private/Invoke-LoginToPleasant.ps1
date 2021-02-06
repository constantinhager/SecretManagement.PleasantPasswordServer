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

    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

    $SecretFile = Get-SecretFile

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