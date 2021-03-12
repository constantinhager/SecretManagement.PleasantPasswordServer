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

    $body = @{
        "search" = "$Filter"
    }

    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

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

    # TODO: Datemagic
    # TODO: Only provide Filename and Size
    # TODO: Return Foldername for GroupID
    [ReadOnlyDictionary[String, Object]]$metadata = [ordered]@{
        CustomUserFields = $CredentialMetadata.CustomUserFields
        Attachments      = $CredentialMetadata.Attachments
        Tags             = $CredentialMetadata.Tags
        Url              = $CredentialMetadata.Url
        Notes            = $CredentialMetadata.Notes
        Created          = $CredentialMetadata.Created
        Modified         = $CredentialMetadata.Modified
        Expires          = $CredentialMetadata.Expires

    } | ConvertTo-ReadOnlyDictionary

    return [SecretInformation]::new(
        $Filter,
        [SecretType]::PSCredential,
        $VaultName,
        $metadata
    )
}