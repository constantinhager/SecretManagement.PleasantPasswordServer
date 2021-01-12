task . Clean, Build
task Build Compile, CreateManifest
task CreateManifest CopyPSD, UpdateModuleVersion

$Root = $env:BUILD_REPOSITORY_LOCALPATH
$srcPath = $env:BUILD_REPOSITORY_LOCALPATH
$ModuleName = [System.IO.Path]::GetFileNameWithoutExtension((Get-ChildItem -Path $srcPath -Filter "*.psd1").Name)
$srcModulePath = Join-Path -Path $srcPath -ChildPath "$($ModuleName).psd1"
[version]$srcModuleVersion = (Import-PowerShellDataFile -Path $srcModulePath).ModuleVersion
$NewModuleVersion = "{0}.{1}.{2}" -f $srcModuleVersion.Major, $srcModuleVersion.Minor, $env:BUILD_BUILDID
$OutPutFolder = Join-Path -Path $env:BUILD_REPOSITORY_LOCALPATH -ChildPath "Release"
$PsmPath = [System.IO.Path]::Combine($env:BUILD_REPOSITORY_LOCALPATH, "Release", $ModuleName, $NewModuleVersion, "$ModuleName.psm1")
$PsdPath = [System.IO.Path]::Combine($env:BUILD_REPOSITORY_LOCALPATH, "Release", $ModuleName, $NewModuleVersion, "$ModuleName.psd1")
$ExtensionPath = [System.IO.Path]::Combine($env:BUILD_REPOSITORY_LOCALPATH, "Release", $ModuleName, $NewModuleVersion)
$LicensePath = [System.IO.Path]::Combine($env:BUILD_REPOSITORY_LOCALPATH, "Release", $ModuleName, $NewModuleVersion, "LICENSE.txt")
$ReadMePath = [System.IO.Path]::Combine($env:BUILD_REPOSITORY_LOCALPATH, "Release", $ModuleName, $NewModuleVersion, "README.md")

task "Clean" {
    if (-not(Test-Path $OutPutFolder))
    {
        $null = New-Item -ItemType Directory -Path $OutPutFolder
    }

    Remove-Item -Path "$($OutPutFolder)\*" -Force -Recurse
}

task Compile {

    New-Item -ItemType Directory -Path $ExtensionPath -Force

    Copy-Item -Path (Join-Path -Path $Root -ChildPath "$($ModuleName).psm1") -Destination $PsmPath -Force
    Copy-Item -Path (Join-Path -Path $Root -ChildPath "$($ModuleName).Extension") -Destination $ExtensionPath -Recurse -Force
    Copy-Item -Path (Join-Path -Path $Root -ChildPath "LICENSE") -Destination $LicensePath -Recurse -Force
    Copy-Item -Path (Join-Path -Path $Root -ChildPath "README.md") -Destination $ReadMePath -Recurse -Force
}

task CopyPSD {
    New-Item -Path (Split-Path $PsdPath) -ItemType Directory -ErrorAction 0
    $copy = @{
        Path        = Join-Path -Path $srcPath -ChildPath "$($ModuleName).psd1"
        Destination = $PsdPath
        Force       = $true
        Verbose     = $true
    }
    Copy-Item @copy
}

task UpdateModuleVersion {
    $manifest = Import-PowerShellDataFile $PsdPath
    [version]$version = $manifest.ModuleVersion
    Write-Output "Old Version - $Version"
    [version]$NewVersion = "{0}.{1}.{2}" -f $Version.Major, $Version.Minor, $env:BUILD_BUILDID
    Write-Output "New Version - $NewVersion"
    # Update the manifest file
    try
    {
        Write-Output "Updating the Module Version to $NewVersion"
        (Get-Content $PsdPath) -replace $version, $NewVersion | Set-Content $PsdPath -Encoding string
        Write-Output "Updated the Module Version to $NewVersion"
    }
    catch
    {
        Write-Error "Failed to update the Module Version - $_"
    }
}
