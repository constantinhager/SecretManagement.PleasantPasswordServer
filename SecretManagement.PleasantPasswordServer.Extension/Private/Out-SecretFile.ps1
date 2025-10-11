function Out-SecretFile
{
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory, ParameterSetName = "LoginToken")]
        [PSCustomObject]
        $LoginToken
    )

    Switch ($PSCmdlet.ParameterSetName){

        "LoginToken"
        {
            Write-Verbose "Saving login token file to disk"
            $SecureToken = [PSCustomObject]@{
                "Access_Token" = ConvertTo-SecureString -String $LoginToken.Access_Token -AsPlainText -Force
                "Expires" = $LoginToken.Expires
            }
            $FilePath = Join-Path -Path $env:TEMP -ChildPath "PleasantToken.xml"
            $SecureToken | Export-Clixml -Path $FilePath
        }

    }

}