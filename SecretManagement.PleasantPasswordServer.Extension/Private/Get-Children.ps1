function Get-Children
{

    <#
    .SYNOPSIS
        Lists all Folders an their credentials recursive.
    .DESCRIPTION
        Lists all Folders an their credentials recursive.
    .PARAMETER Folder
        The current folder in the folderstructure
    .EXAMPLE
        PS C:\> Get-Children -Folder $f
        Lists all Folders an their credentials recursive.
    .INPUTS
        System.Object
    .OUTPUTS
        System.Management.Automation.PSCustomObject[]
    .NOTES
        Author: Constantin Hager
        Date: 2021-03-17
    #>

    param (
        [Parameter(Mandatory)]
        [System.Object]
        $Folder
    )

    if ($null -ne $Folder)
    {
        $returnList = New-object 'System.Collections.Generic.List[System.Object]'

        if ($Folder.Name -eq "Root")
        {
            # Root Folder + Credentials
            $row = [PSCustomObject]@{
                Folder      = $Folder.Name
                FolderID    = $Folder.Id
                Credentials = $Folder.Credentials
            }

            $returnlist.add($row)
        }

        foreach ($subfolder in $Folder.Children)
        {
            # Subfolders + Credentials
            $row = [PSCustomObject]@{
                Folder      = [string]::Concat($Folder.Name, '/', $subfolder.Name)
                FolderID    = $subfolder.Id
                Credentials = $subfolder.Credentials
            }

            $returnlist.add($row)

            foreach ($f in $subfolder)
            {
                Get-Children -Folder $f
            }
        }
    }
    return $returnlist
}