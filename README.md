# cMDT

cMDT is a Powershell Module to help automize MDT server deployment and configuration with Desired State Configuration.

  - Download and install prerequisites
  - Installation and configuration of MDT components
  - Creation of Boot Images
  - Lifecycle management for all components

### Version
1.0.0.4

### Tech

cMDT uses a number of components and open resource kit modules. The following are prerequisites for the module and need to be installed to the inteded deployment server:
* [.Net3.5] - .Net Framweworks 3.5
* [WMF5] - Windows Management Framework 5.0
* [xSmbShare] - DSC Module available from Powershell Gallery
* [PowerShellAccessControl] - DSC Module available from GitHub

(If the folder name in the PowerShellAccessControl ZIP from GitHub is named with an "-master" ending rename folder to module name "PowerShellAccessControl" before installing)

The following prerequisites can automatically be downloaded with the cMDT Module:
* [MicrosoftDeploymentToolkit2013_x64] - Microsoft Deployment Toolkit (MDT) 2013 Update 1 (6.3.8330.1000)
* [adksetup] - Windows Assessment and Deployment Kit (10.1.10586.0)

Note: The MDT and ADK versions must compatible for the DSC modules to work.

And of course the cMDT Module itself which is open source with a [public repository][dill]
 on GitHub or from the Powershell Gallery.

### Installation

To install the cMDT Module from the Powershell Gallery:

```sh
Find-Module cMDT | Install-Module
```

### Quick start
You can use this module with a pull server, an SMB share or a local file repository. The following quick start example use a local file repository. We recommend that you create a Checkpoint/Snapshot of the test deployment server after the initial prerequisites and sourcefiles have been installed/copied.

1. Make sure you have installed all prerequisites.
2. Install the cMDT module on the test deployment server: Find-Module cMDT | Install-Module
3. Create a source directory (Example: C:\Sources) If you use another driveletter and patch you need to edit the configuration file:
(C:\Program Files\WindowsPowerShell\Modules\adl_MDT\1.0.0.0\Examples\Deploy_MDT_Server_ConfigurationData.psd1)
4. Copy install.wim file from a Windows 10 media to C:\Sources and rename the file to install_1.0.0.0.wim
5. Copy the Zip-files PEExtraFiles_1.0.0.0.zip and Scripts_1.0.0.0.zip from the Powershell cMDT Module install directory (C:\Program Files\WindowsPowerShell\Modules\adl_MDT\1.0.0.0\Sources) to the C:\Sources directory. 
5. Run Powershell ISE as Administrator and open the file: C:\Program Files\WindowsPowerShell\Modules\cMDT\1.0.0.0\Examples\Deploy_MDT_Server.ps1
6. Press F5 to run the script. It will take approximately 30 min (Depending on internet capacity and virtualization hardware). The server will reboot ones during this process.

### DscResources

The cMDT Module contain the following DscResources:

* cMDTApplication
* cMDTBootstrapIni
* cMDTCustomize
* cMDTCustomSettingsIni
* cMDTDirectory
* cMDTDriver
* cMDTOperatingSystem
* cMDTPersistentDrive
* cMDTPreReqs
* cMDTTaskSequence
* cMDTUpdateBootImage
* cWDSBootImage
* cWDSConfiguration
 
#### cMDTApplication
cMDTApplication is a DscResource that enables download, import of and lifecycle management of applications in MDT. Applications can be updated and retrieved from a pull server according to Desired State Configuration principles.

Available parameters with example:
* [Ensure] - Present/Absent
* [Version] - Version number
* [Name] - Name
* [Path] - MDT path
* [Enabled] - True/False
* [ShortName] - Shortname
* [Publisher] - Publisher information
* [Language] - Language
* [CommandLine] - Command Line file
* [WorkingDirectory] - Working directory
* [ApplicationSourcePath] - Web link, SMB or local path
* [DestinationFolder] - Destination folder in MDT
* [TempLocation] - Tenmporary download location
* [PSDriveName] - The PSDrive name for the MDT deployment share
* [PSDrivePath] - The physical path to the MDT deployment share

The DscResource will import applications according to the following principle:
* Verify status present or absent
* If present:
    * Append version number to the ApplicationSourcePath together with a .zip extension
    * Verify if the application already exist in MDT, and if determine version
    * If the application does not exist or version number not matched the application will be downloaded
    * The application will be extracted from the Zip archive and imported in to the MDT
* If absent:
    * If application exist it will be removed

Desired State Configuration job example:
```sh
cMDTApplication Teamviewer {
    Ensure = "Present"
    Version = "1.0.0.1"
    Name = "Teamviewer"
    Path = "DS001:\Applications\Core Applications"
    Enabled = "True"
    ShortName = "Teamviewer"
    Publisher = "Teamviewer"
    Language = "en-US"
    CommandLine = "install.cmd"
    WorkingDirectory = ".\"
    ApplicationSourcePath = "$($SourcePath)/TeamViewer_Setup_sv"
    DestinationFolder = "Teamviewer"
    TempLocation = $TempLocation
    PSDriveName = $PSDriveName
    PSDrivePath = $PSDrivePath
}
```

#### cMDTBootstrapIni
cMDTBootstrapIni is a DscResource that enables configuration and lifecycle management of the BootStrap.ini in MDT. This file can be updated and managed from a pull server according to Desired State Configuration principles.

Available parameters with example:
* [Ensure] - Present/Absent
* [Path] - MDT path
* [Content] - True/False

The DscResource will manage the content of this file according to the following principle:
* Verify status present or absent
* If present:
    * Verify content of the local BootStrap.ini file with the configuration in the contract
    * Apply changes if necessary
* If absent:
    *  If absent BootStrap.ini will ve reverted to default state 

Desired State Configuration job example:
```sh
cMDTBootstrapIni ini {
    Ensure = "Present"
    Path = "$($PSDrivePath)\Control\Bootstrap.ini"
    Content = @"
[Settings]
Priority=Default

[Default]
DeployRoot=\\$($ComputerName)\DeploymentShare$
SkipBDDWelcome=YES

;MDT Connect Account
UserID=$($UserName)
UserPassword=$($Password)
UserDomain=$($env:COMPUTERNAME)

;Keyboard Layout
KeyboardLocalePE=041d:0000041d
"@
}
```

#### cMDTCustomize
cMDTCustomize is a DscResource that enables management of custom settings, additional folders and scripts with lifecycle management for MDT. The files can be updated and retrieved from a pull server according to Desired State Configuration principles.

Available parameters with example:
* [Ensure] - Present/Absent
* [Version] - Version number
* [Name] - Name
* [Path] - MDT path
* [SourcePath] - Web link, SMB or local path
* [TempLocation] - Temporary download location
* [Protected] - Protected mode ensures that if even if Ensure is set to Absent the existing folder will not be removed.

The DscResource will import custom settings files and directories according to the following principle:
* Verify status present or absent
* If present:
    * Append version number to the ApplicationSourcePath together with a .zip extension,
    * Verify if the defined folder already exist in MDT, and if determine version
    * If the folder does not exist or version number do not match the zip will be downloaded
    * The zip will be extracted from the archive in to the MDT
* If absent:
    * If the folder has not been defined as protected it will be removed

Desired State Configuration job example:
```sh
cMDTCustomize PEExtraFiles {
    Ensure = "Present"
    Version = "1.0.0.0"
    Name = "PEExtraFiles"
    Path = $PSDrivePath
    SourcePath = "$($SourcePath)/PEExtraFiles"
    TempLocation = $TempLocation
}
cMDTCustomize Scripts {
    Ensure = "Present"
    Version = "1.0.0.0"
    Name = "Scripts"
    Path = $PSDrivePath
    SourcePath = "$($SourcePath)/Scripts"
    TempLocation = $TempLocation
    Protected = $true
}
```

#### cMDTCustomSettingsIni
cMDTCustomSettingsIni is a DscResource that enables configuration and lifecycle management of the CustomSettings.ini in MDT. This file can be updated and managed from a pull server according to Desired State Configuration principles.

Available parameters with example:
* [Ensure] - Present/Absent
* [Path] - MDT path
* [Content] - True/False

The DscResource will manage the content of this file according to the following principle:
* Verify status present or absent
* If present:
    * Verify content of the local BootStrap.ini file with the configuration in the contract
    * Apply changes if necessary
* If absent:
    * If absent CustomSettings.ini will ve reverted to default state 

Desired State Configuration job example:
```sh
cMDTCustomSettingsIni ini {
    Ensure = "Present"
    Path = "$($PSDrivePath)\Control\CustomSettings.ini"
    Content = @"
[Settings]
Priority=SetModelAlias, Init, ModelAlias, Default
Properties=ModelAlias, ComputerSerialNumber

[SetModelAlias]
UserExit=ModelAliasExit.vbs
ModelAlias=#SetModelAlias()#

[Init]
ComputerSerialNumber=#Mid(Replace(Replace(oEnvironment.Item("SerialNumber")," ",""),"-",""),1,11)#

[Default]
OSInstall=Y
_SMSTSORGNAME=Company
HideShell=YES
DisableTaskMgr=YES
ApplyGPOPack=NO
UserDataLocation=NONE
DoCapture=NO
OSDComputerName=CLI%ComputerSerialNumber%

;Local admin password
AdminPassword=C@ang3Me!
SLShare=%DeployRoot%\Logs

OrgName=Company
Home_Page=http://companyURL

;Enable or disable options:
SkipAdminPassword=NO
SkipApplications=YES
SkipBitLocker=NO
SkipCapture=YES
SkipComputerBackup=YES
SkipComputerName=NO
SkipDomainMembership=NO
SkipFinalSummary=NO
SkipLocaleSelection=NO
SkipPackageDisplay=YES
SkipProductKey=YES
SkipRoles=YES
SkipSummary=NO
SkipTimeZone=NO
SkipUserData=YES
SkipTaskSequence=NO

;DomainJoin
JoinDomain=ad.company.net
DomainAdmin=DomainJoinAccount
DomainAdminDomain=ad.company.net
DomainAdminPassword=DomainJoinAccountPassword
MachineObjectOU=OU=Clients,OU=company,DC=ad,DC=company,DC=net

;TimeZone settings
TimeZoneName=W. Europe Standard Time

WSUSServer=http://fqdn:port

;Example keyboard layout.
UserLocale=en-US
KeyboardLocale=en-US
UILanguage=en-US

;Drivers
DriverSelectionProfile=Nothing

;DriverInjectionMode=ALL

FinishAction=RESTART
"@
}
```

#### cMDTDirectory
cMDTDirectory is a DscResource that enables management of folder structures with lifecycle management for MDT. These folders can be managed from a pull server according to Desired State Configuration principles.

Available parameters with example:
* [Ensure] - Present/Absent
* [Name] - Name of folder
* [Path] - MDT path
* [PSDriveName] - The PSDrive name for the MDT deployment share
* [PSDrivePath] - The physical path to the MDT deployment share

The DscResource will manage MDT folders according to the following principle:
* Verify status present or absent
* If present:
    * Check if defined folder exists in MDT
    * If the folder does not exist the folder will be created
* If absent:
    * The folder will be removed

Desired State Configuration job example:
```sh
cMDTDirectory Windows10 {
    Ensure = "Present"
    Name = "Windows 10"
    Path = "DS001:\Operating Systems"
    PSDriveName = $PSDriveName
    PSDrivePath = $PSDrivePath
}
```

#### cMDTDriver
cMDTDriver is a DscResource that enables download, import of and lifecycle management of drivers in MDT. Drivers can be updated and retrieved from a pull server according to Desired State Configuration principles.

Available parameters with example:
* [Ensure] - Present/Absent
* [Version] - Version number
* [Name] - Name
* [Path] - MDT path
* [Enabled] - True/False
* [Comment] - Comments
* [SourcePath] - Web link, SMB or local path
* [TempLocation] - Tenmporary download location
* [PSDriveName] - The PSDrive name for the MDT deployment share
* [PSDrivePath] - The physical path to the MDT deployment share

The DscResource will import drivers according to the following principle:
* Verify status present or absent
* If present:
    * Append version number to the SourcePath together with a .zip extension,
    * Verify if the driver already exist in MDT, and if determine version
    * If the driver does not exist or version number not matched the driver will be downloaded
    * The driver will be extracted from the Zip archive and imported in to the MDT
        * Note that drives will be imported to allow duplicates to prevent accidental deletions
* If absent:
    * The driver will be removed

Desired State Configuration job example:
```sh
cMDTDriver Win10x64DellAudio {
    Ensure = "Present"
    Version = "6.0.1.6070_A00"
    Name = "Latitude 3340"
    Path = "DS001:\Out-of-Box Drivers\Windows 10 x64\Dell Inc."
    Enabled = "True"
    Comment = "Drivers for Dell Latitude 3340 Laptops"
    SourcePath = "$($SourcePath)/Audio_Driver_5P33P_WN32"
    TempLocation = $TempLocation
    PSDriveName = $PSDriveName
    PSDrivePath = $PSDrivePath
}
```

#### cMDTOperatingSystem
cMDTOperatingSystem is a DscResource that enables download, import of and lifecycle management of Operating System WIM files in MDT. These files can be updated and retrieved from a pull server according to Desired State Configuration principles.

Available parameters with example:
* [Ensure] - Present/Absent
* [Version] - Version number (optional)
* [Name] - Name
* [Path] - MDT path
* [SourcePath] - Web link, SMB or local path
* [TempLocation] - Tenmporary download location
* [PSDriveName] - The PSDrive name for the MDT deployment share
* [PSDrivePath] - The physical path to the MDT deployment share

The DscResource will import Operating Systems according to the following principle:
* Verify status present or absent
* If present:
    * If version is defined, appends version number to the SourcePath together with a .wim extension
    * If version is not defined, download checksum version information from the pull server. The checksum file needs to be named as image file name and ".version"; ex: REFW10X64.version.
    * Verify if the Operating System already exist in MDT, and if determine version
    * If the Operating System does not exist or version number do not matched the Operating System WIM file will be downloaded
    * If the Operating System does not exist the WIM file will be imported in to the MDT, if the Operating System do exist and upgrade mode is determined the WIM file will be copied in to the appropriate MDT directory path
* If absent:
    * The operating system will be removed

Desired State Configuration job example:
```sh
cMDTOperatingSystem Win10x64 {
    Ensure = "Present"
    Version = "1.0.0.0"
    Name = "Windows 10 Enterprise x64"
    Path = "DS001:\Operating Systems\Windows 10"
    SourcePath = "$($SourcePath)/REFW10X64"
    TempLocation = $TempLocation
    PSDriveName = $PSDriveName
    PSDrivePath = $PSDrivePath
}
```

#### cMDTPersistentDrive
cMDTPersistentDrive is a DscResource that enables management of MDT persistent drives with lifecycle management for MDT. These folders can be managed from a pull server according to Desired State Configuration principles.

Available parameters with example:
* [Ensure] - Present/Absent
* [Name] - Name of drive
* [Path] - MDT path
* [Description] - A description of the drive
* [NetworkPath] - Network share name of the MDT persistent drive

The DscResource will manage MDT folders according to the following principle:
* Verify status present or absent
* If present:
    * Check if the defined persistent drive exist in MDT
    * If the persistent drive does not exist it will be created
* If absent:
    * The persistent drive will be removed

Desired State Configuration job example:
```sh
cMDTPersistentDrive DeploymentPSDrive {
    Ensure = "Present"
    Name = $PSDriveName
    Path = $PSDrivePath
    Description = "Deployment Share"
    NetworkPath = "\\$ComputerName\DeploymentShare$"
}
```

#### cMDTPreReqs
cMDTPreReqs is a DscResource that enables download of prerequisites for MDT server deployment. Prerequisites can be defined and managed from a pull server according to Desired State Configuration principles.

Available parameters with example:
* [Ensure] - Present/Absent
* [DownloadPath] - Download path for binaries

The DscResource will import applications according to the following principle:
* Check if prerequisites exist in the DownloadPath
* If they do not exist the prerequisites will be downloaded over the internet from Microsoft directly

Desired State Configuration job example:
```sh
cMDTPreReqs MDTPreReqs {
    Ensure = "Present"            
    DownloadPath = "$(TempLocation)"
}
```

#### cMDTTaskSequence
cMDTTaskSequence is a DscResource that enables management of Task Sequences with lifecycle management for MDT. Task Sequences can be defined and managed from a pull server according to Desired State Configuration principles.

Available parameters with example:
* [Ensure] - Present/Absent
* [Name] - Name of drive
* [Path] - MDT path
* [OperatingSystemPath] - MDT path
* [WIMFileName] - Name of Operating System WIM file to create Task Sequence for. Overrides OperatingSystemPath Parameter.
* [ID] - MDT path
* [PSDriveName] - MDT path
* [PSDrivePath] - MDT path

The DscResource will import applications according to the following principle:
* Verify status present or absent
* If present:
    * Check if Task Sequence exist in the MDT path
    * If it does not exist the Task Sequence will be created
* If absent:
    * The Task Sequence will be removed

Note: The Operating System WIM file must exist in the OperatingSystemPath for the Task Sequence to be created correctly.

Desired State Configuration job example:
```sh
cMDTTaskSequence Win10x64 {
    Ensure = "Present"
    Name = "Windows 10 x64"
    Path = "DS001:\Task Sequences\Windows 10"
    #OperatingSystemPath = "DS001:\Operating Systems\Windows 10\REFW10X64DDrive in Windows 10 Enterprise x64 REFW10X64.wim"
    WIMFileName = "REFW10X64"    
    ID = "01"
    PSDriveName = $PSDriveName
    PSDrivePath = $PSDrivePath
}
```

#### cMDTUpdateBootImage
cMDTUpdateBootImage is a DscResource that enables creation and management of boot images with lifecycle management for MDT. Boot images can be defined and managed from a pull server according to Desired State Configuration principles.

Available parameters with example:
* [Version] - Version number
* [PSDeploymentShare] - Name of drive
* [Force] - MDT path
* [Compress] - MDT path
* [DeploymentSharePath] - MDT path

The DscResource will import applications according to the following principle:
* Verify if the boot image exist in MDT, and if determine version
* If the boot image does not exist or version number do not match a boot image will be created

Desired State Configuration job example:
```sh
cMDTUpdateBootImage updateBootImage {
    Version = "1.0.0.0"
    PSDeploymentShare = $PSDriveName
    Force = $true
    Compress = $true
    DeploymentSharePath = $PSDrivePath
}
```

#### cWDSBootImage
cWDSBootImage is a DscResource that enables management of boot images with lifecycle management for the Windows Deployment Services (WDS). Boot images can be defined and managed from a pull server according to Desired State Configuration principles.

Available parameters with example:
* [Ensure] - Present/Absent
* [Path] - Path to the boot image file in MDT
* [ImageName] - Name of the boot imgage file to be created in WDS

The DscResource will import applications according to the following principle:
* Check if boot image exist in the MDT path
* If it does exist the a boot image in WDS will be created

Desired State Configuration job example:
```sh
cWDSBootImage wdsBootImage {
    Ensure = "Present"
    Path = "$($PSDrivePath)\Boot\LiteTouchPE_x64.wim"
    ImageName = "LiteTouchTest X64 v1.0.0.0"
}
```

#### cWDSConfiguration
cWDSConfiguration is a DscResource that enables management and configuration for the Windows Deployment Services (WDS).

Available parameters with example:
* [Ensure] - Present/Absent
* [RemoteInstallPath] - Remote installation path

The DscResource will import applications according to the following principle:
* Check if RemoteInstallPath exist
* If it does not exist the RemoteInstallPath will be created

Desired State Configuration job example:
```sh
cWDSConfiguration wdsConfig {
    Ensure = "Present"
    RemoteInstallPath = "C:\RemoteInstall"
}
```

### Development

Want to contribute? Great!

E-mail us with any changes, questions or suggestions: info@addlevel.se

Or visit us at: http://www.addlevel.se/

License
----

**Free usage!**

[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)


   [github]: <https://github.com/addlevel>


