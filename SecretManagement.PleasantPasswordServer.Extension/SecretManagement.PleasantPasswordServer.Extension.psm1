using namespace Microsoft.PowerShell.SecretManagement

function Invoke-LoginToPleasant
{
    ##############################
    #.SYNOPSIS
    # Login to Pleasant Password Server
    #
    #.DESCRIPTION
    # Login to Pleasant Password Server
    #
    #.PARAMETER AdditionalParameters
    # The following values need to be in there:
    #   ServerURL
    #   Port
    #   Login as PSCredential Object
    #
    #.EXAMPLE
    #   $Password = ConvertTo-SecureString -String "xxx" -AsPlainText -Force
    #   $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "xxx", $Password
    #
    #   $var = @{
    #      ServerURL = "https://ppsdc1.pps.net"
    #      Port      = "10001"
    #      Login     = $Cred
    #   }
    #
    #   Invoke-LoginToPleasant -AdditionalParameters $var
    #
    #.NOTES
    #   Author: Constantin Hager
    #   Date: 2020-12-31
    ##############################


    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Hashtable]
        $AdditionalParameters
    )

    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

    # Create OAuth2 token params
    $tokenParams = @{
        grant_type = 'password';
        username   = $AdditionalParameters.Login.UserName;
        password   = $AdditionalParameters.Login.GetNetworkCredential().password;
    }

    # Authenticate to Pleasant Password Server
    $JSON = Invoke-WebRequest -Uri "$PasswordServerURL/OAuth2/Token" -Method POST -Body $tokenParams -ContentType "application/x-www-form-urlencoded"

    # Generate JSON token
    $Token = (ConvertFrom-Json $JSON.Content).access_token

    return $Token
}