function Get-Secret
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

    if ($null -eq $Token)
    {
        throw "No token received."
    }

    $headers = @{
        "Accept"        = "application/json"
        "Authorization" = "$Token"
    }

    $body = @{
        "search" = "$Name"
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

    $Credential = Invoke-RestMethod -Method get -Uri "$PasswordServerURL/api/v5/rest/credential/$id" -Headers $headers -ContentType 'application/json'
    $Password = Invoke-RestMethod -method post -Uri "$PasswordServerURL/api/v5/rest/credential/$id/password" -body (ConvertTo-Json $body) -Headers $headers -ContentType 'application/json'

    if ([string]::IsNullOrWhiteSpace($Password))
    {
        $PasswordAsSecureString = ConvertTo-SecureString -String " " -AsPlainText -Force
    }
    else
    {
        $PasswordAsSecureString = ConvertTo-SecureString -String $Password -AsPlainText -Force
    }

    if ([string]::IsNullOrWhiteSpace($Credential.UserName))
    {
        $UserName = "notneeded"
    }
    else
    {
        $UserName = $Credential.Username
    }

    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $PasswordAsSecureString

    return $Credential
}