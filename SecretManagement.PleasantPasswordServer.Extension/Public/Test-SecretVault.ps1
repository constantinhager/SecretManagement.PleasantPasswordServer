function Test-SecretVault
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $VaultName,

        [Parameter()]
        [hashtable]
        $AdditionalParameters
    )

    trap
    {
        Write-VaultError -ErrorRecord $_
    }

    # Enable verbose output if directed
    if ($AdditionalParameters.ContainsKey('Verbose') -and ($AdditionalParameters['Verbose'] -eq $true)) {
        $VerbosePreference = 'Continue'
    }

    $Parameters = @{
        ServerURL = $AdditionalParameters.ServerURL
        Port      = $AdditionalParameters.Port
    }

    $Token = Invoke-LoginToPleasant -AdditionalParameters $Parameters

    if ($null -eq $Token)
    {
        return $false
    }
    else
    {
        return $true
    }
}