@{
    ModuleVersion     = '0.2.0'
    RootModule        = '.\SecretManagement.PleasantPasswordServer.Extension.psm1'
    FunctionsToExport = @('Set-Secret', 'Get-Secret', 'Remove-Secret', 'Get-SecretInfo', 'Test-SecretVault')
}
