$ModuleName = 'SecretManagement.PleasantPasswordServer'

function New-PleasantCredential {
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

function Register-PleasantVault {

    <#
    .SYNOPSIS
        Creates a new Pleasant Password Server Vault
    .DESCRIPTION
        Wraps the functionality of Register-SecretVault to make the module more user friedlier
    .PARAMETER VaultName
        The name of the Pleasant Password Server Vault
    .PARAMETER ServerURL
        The Server URL where the Pleasant Password Server is reachable    
    .PARAMETER Port
        The Port where the Pleasant Password Server is reachable
    .EXAMPLE
        Register-PleasantVault -VaultName "PPS" -ServerURL "http://localhost" -Port "9000"
        Creates a new Secret Management Vault named PPS and passes the Vault parameters ServerURL and Port to It
     .EXAMPLE
        Register-PleasantVault -ServerURL "http://localhost" -Port "9000"
        Creates a new Secret Management Vault named SecretManagement.PleasantPasswordServer and passes the Vault parameters ServerURL and Port to It
    .NOTES
        Author: Constantin Hager
        Date: 2021-02-20
    #>

    [CmdletBinding()]
    param (
        # The Vault Name
        [Parameter()]
        [string]
        $VaultName,
        
        # The Server URL where the Pleasant Password Server is reachable
        [Parameter(Mandatory)]
        [string]
        $ServerURL,

        # The Port where the Pleasant Password Server is reachable
        [Parameter(Mandatory)]
        [string]
        $Port
    )
    
    $Params = @{
        ModuleName      = 'SecretManagement.PleasantPasswordServer'
        Name            = if ($PSBoundParameters.ContainsKey('VaultName')) { $VaultName } else { $ModuleName }
        VaultParameters = @{
            ServerURL = $ServerURL
            Port      = $Port
        }
    }
    
    Register-SecretVault @Params
}