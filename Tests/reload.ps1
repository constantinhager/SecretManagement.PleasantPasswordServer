#Legacy Windows 5.1
if ($null -eq $IsWindows)
{
    Function ConvertFrom-SecureString([parameter(ValueFromPipeline)]$InputObject, [Switch]$AsPlainText)
    {
        return [pscredential]::new('MyUser', $InputObject).GetNetworkCredential().Password
    }
}

if (Get-SecretVault 'Pleasant.Tests' -ErrorAction Ignore)
{
    Unregister-SecretVault 'Pleasant.Tests'
}

$modules = 'SecretManagement.PleasantPasswordServer', 'Microsoft.PowerShell.SecretStore', 'Microsoft.PowerShell.SecretManagement'

foreach ($module in $modules)
{
    if (Get-Module $module)
    {
        Remove-Module $module -Force
    }
}

$ModulePath = Join-Path "$PSScriptRoot/.."  'SecretManagement.PleasantPasswordServer.psd1'

$Params = @{
    ServerURL = "https://testserver.local"
    Port      = 8080
}

Register-SecretVault $ModulePath -Name 'Pleasant.Tests' -VaultParameters $Params
Import-Module $ModulePath -Force