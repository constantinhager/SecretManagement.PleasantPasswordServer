function Set-SecretInfo
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [hashtable]
        $Metadata,

        [Parameter(Mandatory)]
        [string]
        $VaultName
    )

    throw [System.NotImplementedException]
}