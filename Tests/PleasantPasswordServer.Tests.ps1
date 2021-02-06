Describe "PleasantPasswordServer.Tests" {
    BeforeAll {
        . $PSScriptRoot/reload.ps1
        $VaultName = 'Pleasant.Tests'
    }

    BeforeEach {
        $secretName = "tests/$((New-Guid).Guid)"
    }

    It 'Pleasant vault is registered' {
        Get-SecretVault $VaultName | Should -Not -BeNullOrEmpty
    }
}