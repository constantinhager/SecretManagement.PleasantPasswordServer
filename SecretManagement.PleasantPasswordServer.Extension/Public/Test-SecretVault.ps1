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