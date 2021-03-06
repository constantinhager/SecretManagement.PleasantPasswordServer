@{

    # Script module or binary module file associated with this manifest.
    RootModule           = 'SecretManagement.PleasantPasswordServer.psm1'

    # Version number of this module.
    ModuleVersion        = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID                 = '023f1450-97f9-4b5d-8b86-558bd86e8ffc'

    # Author of this module
    Author               = 'Constantin Hager'

    # Copyright statement for this module
    Copyright            = '(c) 2020 Constantin Hager. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'A cross-platform Pleasent Password Server Secret Management vault extension. See the README.MD in the module for more details.'

    # Modules that must be imported into the global environment prior to importing this module
    NestedModules        = @(
        './SecretManagement.PleasantPasswordServer.Extension/SecretManagement.PleasantPasswordServer.Extension.psd1'
    )
    RequiredModules      = @(
        "Microsoft.Powershell.SecretManagement"
    )
    PowershellVersion    = '5.1'
    FunctionsToExport    = @('New-PleasantCredential', 'Register-PleasantVault')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags       = 'SecretManagement', 'PleasantPasswordServer', 'SecretVault', 'Vault', 'Secret'
            ProjectUri = 'https://github.com/constantinhager/SecretManagement.PleasantPasswordServer'
        }
    }
}

