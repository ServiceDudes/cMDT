# 1.0.1.x
## Features:
- Pre-requisites dependencies moved to configuration data block in examples script.
- Re-write of the cMDTPreReqs DSC resource.
- New version Microsoft Deployment Toolkit (6.3.8443.1000).
- New version Windows Assessment and Deployment Kit (build 8443).
- Automatic support for deployment share update after upgrade of MDT.
- New role based Azure Automation example scripts.
- Changed process for importing PSD1 files, Invoke-Expression removed.

# 1.0.0.6
## Features:
- Added recursive folder creation and removal capabilities for resources cMDTApplication, cMDTDirectory, cMDTDriver, cMDTOperatingSystem and cMDTTaskSequence.
- Simplified logic to deployment example scripts.
- Added helper for resource module downloads from PowerShell Gallery in deployment example script.
- Added the possibility to add "set variable" steps to a task sequence (see _cMDT_TS_Step_SetVariable_ and the corresponding configuration in the configdata example).
- Added the possibility to enable/disable monitoring (see _cMDTMonitorService_ and the eventservice property under "CustomizeIniFiles" in the configdata example).
- Added the possiblity to create application bundles (see _cMDTApplicationBundle_ and the corresponding configuration in the configdata example).
- Updated the cMDTUpdateBootImage resource to be able to specify which featurepacks to include.
- Updated the cMDTCustomSettingsIni example configdata/buildscript to add a productkey.

## Bugfixes
- Fixed a bug which prevented WDS from being configured if the computer was not part of a domain.

## Known bugs
- The DSC Native User Resource may return an error due to multiple connection failure.
- The DSC Native Service Resource may fail to start the WDSServer service.