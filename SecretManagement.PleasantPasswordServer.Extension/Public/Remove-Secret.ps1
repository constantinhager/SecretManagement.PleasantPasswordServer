function Remove-Secret
{
    param (
        [Parameter(Mandatory)]
        [string]
        $Name,

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

    $Token = Invoke-LoginToPleasant -AdditionalParameters $AdditionalParameters
    $headers = @{
        "Accept"        = "application/json"
        "Authorization" = "$Token"
    }

    $body_search = @{
        "search" = "$Name"
    }

    $body_delete = [ordered]@{
        "Action"  = "Delete"
        "Comment" = "Deleted through SecretsManagement"
    }

    $PasswordServerURL = [string]::Concat($AdditionalParameters.ServerURL, ":", $AdditionalParameters.Port)

    $Secrets = Invoke-RestMethod -method post -Uri "$PasswordServerURL/api/v5/rest/search" -body (ConvertTo-Json $body_search) -Headers $headers -ContentType 'application/json'
    $id = $Secrets.Credentials.id

    if ($id.Count -gt 1)
    {
        throw "Multiple ambiguous entries found for $Name, please remove the duplicate entry"
    }

    if ($null -eq $id)
    {
        throw "No secret with $Name is found"
    }

    $splat = @{
        Uri             = "$PasswordServerURL/api/v5/rest/entries/$id"
        Method          = 'Delete'
        Body            = (ConvertTo-Json $body_delete)
        Headers         = $headers
        ContentType     = 'application/json'
        UseBasicParsing = $true
    }

    $Response = Invoke-WebRequest @splat

    if ($Response.StatusCode -eq 204)
    {
        return $true
    }
    else
    {
        return $false
    }
}