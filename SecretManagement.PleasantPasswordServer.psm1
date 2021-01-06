function New-PleasantCredential
{
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory)]
        [PSCredential]
        $Credential
    )

    $CredentialPath = Join-Path -Path $env:TEMP -ChildPath "PleasantCred.xml"

    $Credential | Export-Clixml -Path $CredentialPath
}