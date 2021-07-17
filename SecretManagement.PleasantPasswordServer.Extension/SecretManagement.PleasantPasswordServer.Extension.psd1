@{
    ModuleVersion     = '1.0.0'
    RootModule        = '.\SecretManagement.PleasantPasswordServer.Extension.psm1'
    FunctionsToExport = @('Set-Secret', 'Get-Secret', 'Remove-Secret', 'Get-SecretInfo', 'Test-SecretVault', 'Set-SecretInfo')
}
