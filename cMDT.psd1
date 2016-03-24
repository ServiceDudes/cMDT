@{

# Script module or binary module file associated with this manifest.
RootModule = 'cMDT.psm1'

DscResourcesToExport = @('cMDTApplication','cMDTBootstrapIni','cMDTCustomize','cMDTCustomSettingsIni','cMDTDirectory','cMDTDriver','cMDTOperatingSystem','cMDTPersistentDrive','cMDTPreReqs','cMDTTaskSequence','cMDTUpdateBootImage','cWDSBootImage','cWDSConfiguration')

CmdletsToExport     = @('Compare-Version','Import-MicrosoftDeploymentToolkitModule','Invoke-ExpandArchive','Invoke-RemovePath','Invoke-TestPath','Invoke-WebDownload','New-ReferenceFile')
FunctionsToExport  = @('Compare-Version','Import-MicrosoftDeploymentToolkitModule','Invoke-ExpandArchive','Invoke-RemovePath','Invoke-TestPath','Invoke-WebDownload','New-ReferenceFile')

# Version number of this module.
ModuleVersion = '1.0.0.4'

# ID used to uniquely identify this module
GUID = '81624038-5e71-40f8-8905-b1a87afe22d7'

# Author of this module
Author = 'ServiceDudes'

# Company or vendor of this module
CompanyName = 'ServiceDudes'

# Copyright statement for this module
Copyright = 'The MIT License (MIT)'

# Description of the functionality provided by this module
Description = 'A DSC Module for installing Microsoft Deployment Toolkit'

# Project site link
HelpInfoURI = 'https://github.com/ServiceDudes/cMDT'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResource', 'MDT', 'Microsoft Deployment Toolkit')

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
