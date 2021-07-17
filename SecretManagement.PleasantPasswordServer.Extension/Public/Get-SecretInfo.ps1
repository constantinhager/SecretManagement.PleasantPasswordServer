using namespace Microsoft.PowerShell.SecretManagement
using namespace System.Collections.ObjectModel
function Get-SecretInfo
{
    param (
        [Parameter(Mandatory)]
        [string]
        $VaultName,

        [Parameter()]
        [string]
        $Filter,

        [Parameter()]
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

    $Filter = $PSBoundParameters.Filter

    if ($Filter -ne '*')
    {
        $body = @{
            "search" = "$Filter"
        }

        $Secrets = Invoke-RestMethod -method post -Uri "$PasswordServerURL/api/v5/rest/search" -body (ConvertTo-Json $body) -Headers $headers -ContentType 'application/json'
        $id = $Secrets.Credentials.id

        if ($id.Count -gt 1)
        {
            throw "Multiple ambiguous entries found for $Name, please remove the duplicate entry"
        }

        if ($null -eq $id)
        {
            throw "No secret with $Name is found"
        }

        $Params = @{
            Method      = 'GET'
            Uri         = "$PasswordServerURL/api/v5/rest/Entries/$id"
            Headers     = $headers
            ContentType = 'application/json'
        }

        $CredentialMetadata = Invoke-RestMethod @Params

        $param = @{
            ServerURL = $PasswordServerURL
            Token     = $Token
            GroupID   = $CredentialMetadata.GroupId
        }

        $FolderPath = Get-SecretFolder @param

        $Name = $CredentialMetadata.Name

        [ReadOnlyDictionary[String, Object]]$metadata = [ordered]@{
            CustomUserFields = $CredentialMetadata.CustomUserFields
            Attachments      = $CredentialMetadata.Attachments
            Tags             = $CredentialMetadata.Tags
            Url              = $CredentialMetadata.Url
            Notes            = $CredentialMetadata.Notes
            Created          = if ([string]::IsNullOrWhiteSpace($Credential.Created))
            {
                ''
            }
            else
            {
                [DateTime]$Credential.Created
            }
            Modified         = if ([string]::IsNullOrWhiteSpace($Credential.Modified))
            {
                ''
            }
            else
            {
                [DateTime]$Credential.Modified
            }
            Expires          = if ([string]::IsNullOrWhiteSpace($Credential.Expires))
            {
                ''
            }
            else
            {
                [DateTime]$Credential.Expires
            }
            FolderName       = $FolderPath[0]
            Id               = $Folder.FolderID
        } | ConvertTo-ReadOnlyDictionary

        return [SecretInformation]::new(
            $Name,
            [SecretType]::PSCredential,
            $VaultName,
            $metadata
        )
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

        [Object[]]$secretInfoResult = foreach ($Folder in $PPSStructure)
        {
            # Credentials
            $AllCredentials = $Folder.Credentials

            foreach ($Credential in $AllCredentials)
            {
                $Name = $Credential.Name

                [ReadOnlyDictionary[String, Object]]$metadata = [ordered]@{
                    CustomUserFields = $Credential.CustomUserFields
                    Attachments      = $Credential.Attachments
                    Tags             = $Credential.Tags
                    Url              = $Credential.Url
                    Notes            = $Credential.Notes
                    Created          = if ([string]::IsNullOrWhiteSpace($Credential.Created))
                    {
                        ''
                    }
                    else
                    {
                        [DateTime]$Credential.Created
                    }
                    Modified         = if ([string]::IsNullOrWhiteSpace($Credential.Modified))
                    {
                        ''
                    }
                    else
                    {
                        [DateTime]$Credential.Modified
                    }
                    Expires          = if ([string]::IsNullOrWhiteSpace($Credential.Expires))
                    {
                        ''
                    }
                    else
                    {
                        [DateTime]$Credential.Expires
                    }
                    FolderName       = $Folder.Folder
                    Id               = $Folder.FolderID
                } | ConvertTo-ReadOnlyDictionary

                [SecretInformation]::new(
                    $Name,
                    [SecretType]::PSCredential,
                    $VaultName,
                    $metadata
                )

            }
        }

        [Object[]]$sortedInfoResult = $secretInfoResult | Sort-Object -Unique -Property Name
        if ($sortedInfoResult.count -lt $secretInfoResult.count)
        {
            $nonUniqueFilteredRecords = Compare-Object $sortedInfoResult $secretInfoResult -Property Name | Where-Object SideIndicator -eq '=>'
            Write-Warning "Vault ${VaultName}: Entries with non-unique titles were detected, the duplicates were filtered out.)"
            Write-Warning "Vault ${VaultName}: Filtered Non-Unique Titles: $($nonUniqueFilteredRecords.Name -join ', ')"
        }

        return $secretInfoResult
    }
}