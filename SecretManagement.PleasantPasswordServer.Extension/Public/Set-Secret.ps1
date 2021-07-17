function Set-Secret
{
    param (

        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [object]
        $Secret,

        [Parameter(Mandatory)]
        [string]
        $VaultName,

        [Parameter()]
        [hashtable]
        $Metadata,

        [Parameter(Mandatory)]
        [hashtable]
        $AdditionalParameters
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

    if($Metadata.FolderName -eq "Root")
    {
        $splat = @{
            Uri = "$PasswordServerURL/api/v5/rest/folders/root"
            Headers = $headers
            ContentType = 'application/json'
        }
        $FolderID = Invoke-RestMethod @splat
    }
    else
    {
        $Params = @{
            Method      = 'GET'
            Uri         = "$PasswordServerURL/api/v5/rest/folders/"
            Headers     = $headers
            ContentType = 'application/json'
        }

        $AllFolders = Invoke-RestMethod @Params
        $PPSStructure = Get-Children -Folder $AllFolders

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
    }


    if ($Secret -is [System.Management.Automation.PSCredential])
    {
        $body_add = [ordered]@{
            "CustomUserFields"        = $Metadata.CustomUserFields
            "Tags"                    = $Metadata.Tags
            "Name"                    = $Name
            "UserName"                = $Secret.UserName
            "Password"                = $Secret.GetNetworkCredential().Password
            "Url"                     = $Metadata.Url
            "Notes"                   = $Metadata.Notes
            "GroupId"                 = $FolderID
            "Expires"                 = $Metadata.Expires
        }
    }

    if ($Secret -is [System.Security.SecureString])
    {
        $body_add = [ordered]@{
            "CustomUserFields"        = $Metadata.CustomUserFields
            "Tags"                    = $Metadata.Tags
            "Name"                    = $Name
            "UserName"                = ""
            "Password"                = ConvertFrom-SecureString -SecureString $Secret
            "Url"                     = $Metadata.Url
            "Notes"                   = $Metadata.Notes
            "GroupId"                 = $FolderID
            "Expires"                 = $Metadata.Expires
        }
    }

    if ($null -eq $body_add)
    {
        return $false
    }
    else
    {
        $splat = @{
            Uri             = "$PasswordServerURL/api/v5/rest/entries/"
            Method          = 'POST'
            Body            = (ConvertTo-Json $body_add)
            Headers         = $headers
            ContentType     = 'application/json'
            UseBasicParsing = $true
        }

        $Response = Invoke-WebRequest @splat

        if ($Response.StatusCode -eq 200)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
}