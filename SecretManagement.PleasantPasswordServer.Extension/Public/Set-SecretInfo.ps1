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

    # Convert metadata to Json
    # Add GroupId to Metadata Array

    if($Metadata.ContainsKey("FolderName"))
    {
        if($Metadata.FolderName.Split('/').Count -gt 2)
        {
            $Split = $Metadata.FolderName.Split('/')
            $Path1 = $Split[$Split.Length-2]
            $Path2 = $Split[$Split.Length-1]
            $FullPath = [string]::Concat($Path1, "/", $Path2)
        }
        else
        {
            $FullPath = $Metadata.FolderName
        }

        $FolderID = $PPSStructure | Where-Object {$_.Folder -eq $FullPath} | Select-Object -ExpandProperty FolderID
        $Metadata.Remove("FolderName")
    }
    else
    {
        $FolderID = $Secret.GroupId
    }

    $Metadata.Add("GroupId", "$FolderID")
    $Metadata.Add("Id", "$($Secret.Id)")

    $JSONString = $Metadata | ConvertTo-Json -Depth 10

    # Patch
    $Params = @{
        Method      = 'PATCH'
        Uri         = "$PasswordServerURL/api/v5/rest/entries/$($Secret.Id)"
        Headers     = $headers
        ContentType = 'application/json'
        Body        = $JSONString
    }

    Invoke-RestMethod @Params

}