function Get-SecretFile
{
    [CmdletBinding()]
    Param(
        
        [Parameter(Mandatory, ParameterSetName = "VaultCredential")]
        [Switch]$VaultCredential,

        [Parameter(Mandatory, ParameterSetName = "LoginToken")]
        [Switch]$LoginToken

    )

    Switch ($PSCmdlet.ParameterSetName)
    {

        "VaultCredential"
        {
            $FilePath = Join-Path -Path $env:TEMP -ChildPath "PleasantCred.xml"

            if (Test-Path -Path $FilePath)
            {
                $Credential = Import-Clixml -Path $FilePath
                Write-Verbose "Credentials found for user '$($Credential.Username)'."
                return $Credential
            }
            else
            {
                throw "Credential File not found. Please import the module and run New-PleasantCredential to create the file."
            }
        }

        "LoginToken"
        {
            $FilePath = Join-Path -Path $env:TEMP -ChildPath "PleasantToken.xml"

            if (Test-Path -Path $FilePath)
            {
                $SecureToken = Import-Clixml -Path $FilePath
                Write-Verbose "Login token file found."
                $Token = [PSCustomObject]@{
                    "Access_Token" = [System.Net.NetworkCredential]::new('', $SecureToken.Access_Token).Password
                    "Expires" = $SecureToken.Expires
                }
                return $Token
            }
            else
            {
                Write-Verbose "Login token file not found."
                return
            }
        }

    }
    
}