# SecretManagement extension for Pleasant Password Server

This is a [SecretManagement](https://github.com/PowerShell/SecretManagement) extension for PleasantPasswordServer. It leverages the REST API that
is built into Pleasant Password Server.

> **NOTE: This is not a maintained project and it's specifically not maintained _by_ the creators of Pleasant Password Server.**
> **I work on it in my free time because I use Pleasant Password Server in my company.**

## Prerequisites

* [PowerShell](https://github.com/PowerShell/PowerShell) (It is also usable with PowerShell 5.1)
* The [SecretManagement](https://github.com/PowerShell/SecretManagement) PowerShell module

You can get the `SecretManagement` module from the PowerShell Gallery:

Using PowerShellGet v2:

```pwsh
Install-Module Microsoft.PowerShell.SecretManagement
```

Using PowerShellGet v3:

```pwsh
Install-PSResource Microsoft.PowerShell.SecretManagement
```

## Installation

You an install this module from the PowerShell Gallery:

Using PowerShellGet v2:

```pwsh
Install-Module SecretManagement.PleasantPasswordServer
```

Using PowerShellGet v3:

```pwsh
Install-PSResource SecretManagement.PleasantPasswordServer
```

## Registration

Once you have it installed,
you need to register the module as an extension:

```pwsh
Register-SecretVault -ModuleName SecretManagement.PleasantPasswordServer
```

Optionally, you can set it as the default vault by also providing the
`-DefaultVault`
parameter.

At this point,
you should be able to use
`Get-Secret`, `Set-Secret`
and all the rest of the
`SecretManagement`
commands!

### Vault parameters

The module also has the following vault parameters, that can be provided at registration.

#### [string] ServerURL

Provide the URL where your Pleasant Password Server is reachable

#### [string] Port

Provide the Port where your Pleasant Password Server is reachable

##### Examples

* Connecting to your Pleasant Password Server

```pwsh
# Using SecretManagement interface
Register-SecretVault -ModuleName 'SecretManagement.PleasantPasswordServer' -VaultParameters @{
    ServerURL = 'your server url'
    Port      = 'your port'
}
```

To Authenticate against Pleasant Password Server you have to provide your
credentials. Use `New-PleasantCredential`

## Additional Functions

### Register-PleasantVault

Wraps the functionality of Register-SecretVault to make the module more user friedlier.

#### Parameters

##### [String] VaultName (Not mandatory)

The name of your Pleasant Password Server Vault.

##### [String] ServerURL

The Server URL where the Pleasant Password Server is reachable

##### [String] Port

The Port where the Pleasant Password Server is reachable

### New-PleasantCredential

Stores the credentials for Pleasant Password Server to disk

#### Parameters

##### [PSCredential] Credential

A PSCredential Object with your credentials for your Pleasant Password Server

## Metadata Array

If you want to add or change a secret you can change the following metadata:

| Field Name       | Type      |
| ---------------- | --------- |
| CustomUserFields | Hashtable |
| Tags             | Hashtable |
| Name             | String    |
| Username         | String    |
| Password         | String    |
| Url              | String    |
| Notes            | String    |
| FolderName       | String    |
| Created          | DateTime  |
| Modified         | DateTime  |
| Expires          | DateTime  |

> **You do not have to provide the whole array.**

You can provide this hashtable to `Set-SecretInfo`.

```powershell

$Metadata = @{
    CustomUserFields =  @{
        CF2=2
        CF1=1
    }
    Tags             = @(
        @{
            Name="Tag1"
         },
        @{
            Name="Tag2"
         }
    )
    Name             = 'MetadataTest'
    Username         = 'admin'
    Password         = 'Password'
    Url              = 'http://www.google.de'
    Notes            = 'This is the metadata test'
    FolderName       = 'Root/NewFolder'
    Created          = (Get-Date)
    Modified         = (Get-Date)
    Expires          = (Get-Date)
}

```

For `Set-Secret` use the following hastable:

```powershell

$Metadata = @{
        Url                     = "http://localhost"
        CustomUserFields        = @{
            F=1
            C=2
        }
        Tags = @(
            @{Name="Tag1"}
            @{Name="Tag2"}
        )

        Notes                   = "This is another note 1"
        Created                 = (Get-Date)
        Modified                = (Get-Date)
        Expires                 = (Get-Date)
        FolderName              = "Root/NewFolder"
}
```
