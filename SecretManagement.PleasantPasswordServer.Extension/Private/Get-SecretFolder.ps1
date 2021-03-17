function Get-SecretFolder
{
    <#
    .SYNOPSIS
        Get the folderstructure for a single secret
    .DESCRIPTION
        Get the folderstructure for a single secret
    .EXAMPLE
        $param = @{
            ServerURL = '<your server url>'
            Token     = '<your token>'
            GroupID   = '<your group id>'
        }

        PS C:\> Get-SecretFolder @param
        Get the folderstructure for a single secret
    .INPUTS
        System.String,
        System.String
        System.String
    .OUTPUTS
        System.String[]
    .NOTES
        Author: Constantin Hager
        Date: 2021-03-17
    #>

    param
    (
        $ServerURL,
        $Token,
        $GroupID
    )

    if ($GroupID -eq "00000000-0000-0000-0000-000000000000")
    {
        $FolderString = 'Root'
        return
    }

    $headers = @{
        "Accept"        = "application/json"
        "Authorization" = "$Token"
    }

    $Params = @{
        Method      = 'GET'
        Uri         = "$ServerURL/api/v5/rest/folders/$($GroupId)?recurseLevel=0"
        Headers     = $headers
        ContentType = 'application/json'
    }
    $FolderMetadata = Invoke-RestMethod @Params

    $Folderstring = [string]::Concat($FolderMetadata.Name, '/', $FolderString)
    Get-SecretFolder -ServerURL $ServerURL -Token $Token -GroupID $FolderMetadata.ParentId
    return $Folderstring
}