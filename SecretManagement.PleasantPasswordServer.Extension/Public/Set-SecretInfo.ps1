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
        [hashtable]
        $AdditionalParameters,

        [Parameter(Mandatory)]
        [string]
        $VaultName
    )

    trap
    {
        Write-VaultError -ErrorRecord $_
    }

    $Token = Invoke-LoginToPleasant -AdditionalParameters $AdditionalParameters
    $headers = @{
        "Accept"        = "application/json"
        "Authorization" = "$Token"
    }

    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

    $Params = @{
        Method      = 'GET'
        Uri         = "$PasswordServerURL/api/v5/rest/folders/"
        Headers     = $headers
        ContentType = 'application/json'
    }

    $AllFolders = Invoke-RestMethod @Params
    $PPSStructure = Get-Children -Folder $AllFolders

    # Get the secret
    $Secret = $PPSStructure.Credentials | Where-Object { $_.Name -eq $Name }

    if ($null -eq $Secret)
    {
        throw "No secret with $Name is found"
    }

    if ($Secret.Count -gt 1)
    {
        throw "Multiple ambiguous entries found for $Name, please remove the duplicate entry"
    }

    #TODO: If FolderName is there get the id for the folder and write it back to the metadata hashtable
    #TODO: Compare the current Secret with the metadata array
    #TODO: If Metadata Array contains the Password convert It back to plaintext
    #TODO: Write the changes back to the secret

    # Get the folder ID
    #$FolderId = $PPSStructure | Where-Object { $_.Id -eq $Metadata.FolderName }


}