$moduleName     = "cMDT"
$allResources   = @( Get-ChildItem -Path $PSScriptRoot\src\DSCResources\*.psm1 -ErrorAction SilentlyContinue -Recurse | Sort-Object)
$allFunctions   = @( Get-ChildItem -Path $PSScriptRoot\src\Public\*.ps1 -ErrorAction SilentlyContinue -Recurse | Sort-Object)
$moduleVersion  = $env:APPVEYOR_BUILD_VERSION
$combinedModule = "$PSScriptRoot\Builds\$moduleName\$moduleVersion\$ModuleName.psm1"
$manifestFile   = "$PSScriptRoot\Builds\$moduleName\$moduleVersion\$ModuleName.psd1"
$moduleGuid     = "81624038-5e71-40f8-8905-b1a87afe22d7"
$year           = (Get-Date).Year
[string]$dscResourcesToExport = $null


$ensureDefiniton = @"
enum Ensure
{
    Absent
    Present
}


"@

[string]$combinedResources = $ensureDefiniton

Foreach($resource in @($allResources))
{
    Try
    {
        $resourceContent = Get-Content $resource -Raw
        $combinedResources += $resourceContent.Substring($resourceContent.IndexOf("[DscResource()]"))

        if ($resourceContent -match 'class\s*(?<ClassName>\w*)[\r\t]')
        {
            foreach ($match in $Matches.ClassName)
            {
                [string]$dscResourcesToExport += "'$match',"
            }
        }
        
    }
    Catch
    {
        throw $_
    }
}

Foreach($function in @($allFunctions))
{
    Try
    {
        $functionContent = Get-Content $function -Raw
        $combinedResources += $functionContent.Substring($functionContent.IndexOf("Function"))    
    }
    Catch
    {
        throw $_
    }
}

ForEach ($scriptFile in (Get-ChildItem -Path "C:\Repo\cMDT\src\Examples" -Filter "*.ps1"))
{
    $fileContent = Get-Content $scriptFile.FullName -Raw
    $fileContent -replace "\[BUILD_VERSION\]", "$($env:APPVEYOR_BUILD_VERSION)" | Set-Content $scriptFile.FullName
}

Copy-Item -Path "$PSScriptRoot\src\Examples" -Destination "$PSScriptRoot\Builds\$moduleName\$moduleVersion\Examples" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\src\Sources"  -Destination "$PSScriptRoot\Builds\$moduleName\$moduleVersion\Sources" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\Readme.md"    -Destination "$PSScriptRoot\Builds\$moduleName\$moduleVersion\Readme.md" -Recurse -Force
Copy-Item -Path "$PSScriptRoot\Changelog.md" -Destination "$PSScriptRoot\Builds\$moduleName\$moduleVersion\Changelog.md" -Recurse -Force

$dscResourcesToExport = $dscResourcesToExport.TrimEnd(",")
$ManifestDefinition = @"
@{

# Script module or binary module file associated with this manifest.
RootModule = '$moduleName.psm1'

DscResourcesToExport = @($dscResourcesToExport)

CmdletsToExport     = @('Compare-Version','Import-MicrosoftDeploymentToolkitModule','Invoke-ExpandArchive','Invoke-RemovePath','Invoke-TestPath','Invoke-CreatePath','Invoke-WebDownload','New-ReferenceFile','Invoke-Logger','Write-Log','Get-Separator','Get-FileNameFromPath','Get-FileTypeFromPath','Get-FolderNameFromPath','Get-MsiProperty')
FunctionsToExport  = @('Compare-Version','Import-MicrosoftDeploymentToolkitModule','Invoke-ExpandArchive','Invoke-RemovePath','Invoke-TestPath','Invoke-CreatePath','Invoke-WebDownload','New-ReferenceFile','Invoke-Logger','Write-Log','Get-Separator','Get-FileNameFromPath','Get-FileTypeFromPath','Get-FolderNameFromPath','Get-MsiProperty')

# Version number of this module.
ModuleVersion = '$moduleVersion'

# ID used to uniquely identify this module
GUID = '$moduleGuid'

# Author of this module
Author = 'ServiceDudes'

# Description of the functionality provided by this module
Description = 'Microsoft Deployment Toolkit installation and configuration as code. A Desired State Configuration module that enables a subscription based delivery of operating systems, models and applications' 

# Company or vendor of this module
CompanyName = 'ServiceDudes'

# Copyright statement for this module
Copyright = '(c) $Year ServiceDudes. All rights reserved.'

# Description of the functionality provided by this module
# Description = 'Microsoft Deployment Toolkit installation and configuration as code. A Desired State Configuration module that enables a subscription based delivery of operating systems, models and applications'

# Project site link
HelpInfoURI = 'https://github.com/ServiceDudes/cMDT'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResource', 'MDT', 'MicrosoftDeploymentToolkit')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/ServiceDudes/cMDT'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/ServiceDudes/cMDT'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''
}
"@

If (-not (Test-Path -Path "$PSScriptRoot\Builds\$moduleName\$moduleVersion")) { New-Item -ItemType Directory -Path "$PSScriptRoot\Builds\$moduleName\$moduleVersion" }
Set-Content -Path $combinedModule -Value $combinedResources
Set-Content -Path $manifestFile -Value $ManifestDefinition