function Write-VaultError
{
    param
    (
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    <#
    .SYNOPSIS
    Takes a terminating error and first writes it as a non-terminating error to the user to better surface the issue.
    .NOTES
    This was taken from Justin Grote and his Keepass extension https://github.com/JustinGrote/SecretManagement.KeePass
    #>

    $lastErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    Write-Error -Message "Vault ${VaultName}: $($ErrorRecord.Exception.Message)"
    $ErrorActionPreference = $lastErrorActionPreference
    throw $ErrorRecord
}
