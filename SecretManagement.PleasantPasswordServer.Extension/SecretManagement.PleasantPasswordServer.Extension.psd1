@{
    ModuleVersion = '0.1.0'
    RootModule = '.\SecretManagement.PleasantPasswordServer.Extension.psm1'
    FunctionsToExport = @('Set-Secret', 'Get-Secret', 'Remove-Secret', 'Get-SecretInfo', 'Test-SecretVault')
}
