@{
    ModuleVersion = '0.0.4.4'
    RootModule = '.\SecretManagement.PleasantPasswordServer.Extension.psm1'
    FunctionsToExport = @('Set-Secret', 'Get-Secret', 'Remove-Secret', 'Get-SecretInfo', 'Test-SecretVault')
}
