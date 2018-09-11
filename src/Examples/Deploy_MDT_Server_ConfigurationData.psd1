# For instructions of how to edit this file and detailed usage of the module
# open your prefered Internet browser and use the following link:
# https://github.com/addlevel/cMDT

@{
    AllNodes = 
    @(
        @{

            #Global Settings for the configuration of Desired State Local Configuration Manager:
            NodeName                    = "*"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
            RebootNodeIfNeeded          = $true
            ConfigurationMode           = "ApplyAndAutoCorrect"      

        },


        @{

            #Node Settings for the configuration of an MDT Server.
            NodeName                = "$env:computername"
            Role                    = "MDT Server"

            #SMB or web link to a pull server
            SourcePath              = "D:\Sources"

            #Local account to create for MDT. Used for making the connection to the deployment share.
            MDTLocalAccount         = "<Username>"
            MDTLocalPassword        = "<Password>"

            #Local administrator password on deployed clients.
            LocalAdminPassword      = "<Password>"

            #Download and extraction temporary folder
            TempLocation            = "D:\Temp"

            #MDT deoployment share paths
            PSDriveName             = "DS001"
            PSDrivePath             = "D:\DeploymentShare"

            #SMB share name for the deployment share. 
            PSDriveShareName        = "DeploymentShare$"
            
            #Selection profile creation
            SelectionProfiles       = @("WinPE x64")

            #MDT Software installation prerequisites
            MDTInstallationSoftware = @{
                MDT = @(
                    @{  
                        Ensure       = "Present"
                        Name         = "Microsoft Deployment Toolkit (6.3.8450.1000)"
                        ProductId    = "38D2CBE2-862C-4C39-8D65-A4C1C2220160"
                        SourcePath   = "https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi"
                        DownloadPath = "Microsoft Deployment Toolkit"
                    }
                )
                ADK = @(
                    @{                
                        Ensure       = "Present"
                        Name         = "Windows ADK for Windows 10, version 1709"
                        ProductId    = "75ed7648-6cdf-4e09-b2fe-41e985652c96"
                        SourcePath   = "http://download.microsoft.com/download/3/1/E/31EC1AAF-3501-4BB4-B61C-8BD8A07B4E8A/adk/adksetup.exe"
                        DownloadPath = "Windows Assessment and Deployment Kit"
                    }
                )
            }

            #Drivers to import
            Drivers                 = @(
                @{  
                    Ensure     = "Present"
                    Name       = "VMwareTools"
                    Version    = "1.0.0.0"
                    Path       = "\Out-of-Box Drivers\VMware"
                    SourcePath = "\VMware"
                    Comment    = "Drivers for VMware virtual machine"
                }
            )

            #Applications to import
            Applications            = @(
                @{  
                    Ensure                = "Present"
                    Name                  = "VMware Tools"
                    Version               = "10.1.10.6082533"
                    Path                  = "\Applications\VMware Tools"
                    ShortName             = "VMwareTools"
                    Publisher             = "VMware"
                    Language              = "en-US"
                    CommandLine           = "msiexec.exe /i VMwareTools10.1.10.6082533.msi TRANSFORMS=VMwareTools10.1.10.6082533.mst /qn"
                    WorkingDirectory      = ".\Applications\VMwareTools"
                    ApplicationSourcePath = "/Applications/VMwareTools"
                    DestinationFolder     = "VMwareTools"
                },
                @{  
                    Ensure                = "Present"
                    Name                  = "DSC Modules"
                    Version               = "1.0.0.0"
                    Path                  = "\Applications\DSC Modules"
                    ShortName             = "DSCModules"
                    Publisher             = "Custom"
                    Language              = "en-US"
                    CommandLine           = 'powershell.exe -executionpolicy bypass -noprofile -noninteractive -windowstyle hidden -file ".\_install.ps1"'
                    WorkingDirectory      = ".\Applications\DSCModules"
                    ApplicationSourcePath = "/Applications/DSCModules"
                    DestinationFolder     = "DSCModules"
                },
                @{  
                    Ensure                = "Present"
                    Name                  = "DSC Software"
                    Version               = "1.0.0.0"
                    Path                  = "\Applications\DSC Software"
                    ShortName             = "DSCSoftware"
                    Publisher             = "Custom"
                    Language              = "en-US"
                    CommandLine           = 'powershell.exe -executionpolicy bypass -noprofile -noninteractive -windowstyle hidden -file ".\_install.ps1"'
                    WorkingDirectory      = ".\Applications\DSCSoftware"
                    ApplicationSourcePath = "/Applications/DSCSoftware"
                    DestinationFolder     = "DSCSoftware"
                }
            )

            #Operating systems to import to MDT
            OperatingSystems        = @(
                @{  
                    Ensure     = "Present"
                    Name       = "Windows Server 2016 x64"
                    Version    = "1.0.0.0"
                    Path       = "\Operating Systems\Windows Server 2016"
                    SourcePath = "\Install"
                }
            )

            #Task sqeuences; are dependent on imported Operating system in MDT
            TaskSequences           = @(
                @{  
                    Ensure              = "Present"
                    Name                = "Windows Server 2016"
                    Path                = "Task Sequences\Windows Server 2016"
                    OperatingSystemPath = "Operating Systems\Windows Server 2016\Windows Server 2016 SERVERDATACENTER in Windows Server 2016 x64 Install.wim"
                    WIMFileName         = ""
                    ID                  = "REF-S16-X64-001"
                    Template            = "Server.xml"
                    OrgName             = "FK"
                }
            )

            TaskSequenceCustomize   = @(
                @{
                    Name        = "VMware Tools"
                    Path        = "State Restore\Custom Tasks"
                    TSFile      = "D:\DeploymentShare\Control\REF-S16-X64-001\ts.xml"
                    Type        = "Install Application"
                    Description = "Install VMware Tools 10.1.10.6082533"
                    PSDriveName = "DS001"
                    PSDrivePath = "D:\DeploymentShare"
                },
                @{
                    Name        = "DSC Modules"
                    Path        = "State Restore\Custom Tasks"
                    TSFile      = "D:\DeploymentShare\Control\REF-S16-X64-001\ts.xml"
                    Type        = "Install Application"
                    Description = "Copy DSC Modules"
                    PSDriveName = "DS001"
                    PSDrivePath = "D:\DeploymentShare"
                },
                @{
                    Name        = "DSC Software"
                    Path        = "State Restore\Custom Tasks"
                    TSFile      = "D:\DeploymentShare\Control\REF-S16-X64-001\ts.xml"
                    Type        = "Install Application"
                    Description = "Copy DSC Software"
                    PSDriveName = "DS001"
                    PSDrivePath = "D:\DeploymentShare"
                },
                @{
                    Name            = "Set OSDAnswerFilePath"
                    Path            = "State Restore\Imaging\Sysprep Only"
                    TSFile          = "D:\DeploymentShare\Control\REF-S16-X64-001\ts.xml"
                    Type            = "Set Task Sequence Variable"
                    Description     = "Path to custom Unattend.xml"
                    TSVariableName  = "OSDAnswerFilePath"
                    TSVariableValue = "%SCRIPTROOT%\FKUnattend.xml"
                },
                @{
                    Name            = "Set Allocation Unit Size (16K)"
                    Path            = "Preinstall\New Computer only"
                    TSFile          = "D:\DeploymentShare\Control\REF-S16-X64-001\ts.xml"
                    Type            = "Run Command Line"
                    Description     = "Allocation unit size is set to 16K for OSDrive"
                    Command         = 'PowerShell.exe -Command "& {Get-Partition | Where-Object {$_.PartitionNumber -eq 2} | Format-Volume -AllocationUnitSize 16384}"'
                }
            )
            
            TaskSequenceModifyStep  = @(
                @{
                    Name    = "Execute Sysprep"
                    Path    = "State Restore\Imaging\Sysprep Only"
                    TSFile  = "D:\DeploymentShare\Control\REF-S16-X64-001\ts.xml"
                    Disable = "false"
                },
                @{
                    Name    = "Add mass storage drivers to sysprep.inf for XP and 2003"
                    Path    = "State Restore\Imaging\Sysprep Only"
                    TSFile  = "D:\DeploymentShare\Control\REF-S16-X64-001\ts.xml"
                    Disable = "true"
                },
                @{
                    Name    = "Windows Update (Pre-Application Installation)"
                    Path    = "State Restore"
                    TSFile  = "D:\DeploymentShare\Control\REF-S16-X64-001\ts.xml"
                    Disable = "false"
                },
                @{
                    Name    = "Windows Update (Post-Application Installation)"
                    Path    = "State Restore"
                    TSFile  = "D:\DeploymentShare\Control\REF-S16-X64-001\ts.xml"
                    Disable = "false"
                }
            )

            #Custom settings and boot ini file management
            CustomizeIniFiles       = @(
                @{  
                    Ensure               = "Present"
                    Name                 = "CustomSettingsIni"
                    Path                 = "\Control\CustomSettings.ini"
                    HomePage             = "about:blank"
                    SkipAdminPassword    = "YES"
                    SkipApplications     = "YES"
                    SkipBitLocker        = "YES"
                    SkipCapture          = "YES"
                    SkipComputerBackup   = "YES"
                    SkipComputerName     = "YES"
                    SkipDomainMembership = "YES"
                    SkipFinalSummary     = "NO"
                    SkipLocaleSelection  = "YES"
                    SkipPackageDisplay   = "YES"
                    SkipProductKey       = "YES"
                    SkipRoles            = "YES"
                    SkipSummary          = "YES"
                    SkipTimeZone         = "YES"
                    SkipUserData         = "YES"
                    SkipTaskSequence     = "NO"
                    JoinDomain           = ""
                    DomainAdmin          = ""
                    DomainAdminDomain    = ""
                    DomainAdminPassword  = ""
                    MachineObjectOU      = ""
                    TimeZoneName         = ""
                    WSUSServer           = "http://dcspwinf0001.dc.sgdc.se:8530"
                    UserLocale           = "en-US"
                    KeyboardLocale       = "en-US"
                    UILanguage           = "en-US"
                    ProductKey           = ""
                    EventService         = ""
                }
                @{  
                    Ensure           = "Present"
                    Name             = "BootstrapIni"
                    Path             = "\Control\Bootstrap.ini"
                    DeployRoot       = "\DeploymentShare$"
                    KeyboardLocalePE = "0411:E0010411"
                }
            )

            #Boot image creation and management
            BootImage               = @(
                @{  
                    Ensure                  = "Present"
                    Version                 = "1.0.0.2"
                    Path                    = "\Boot\LiteTouchPE_x64.wim"
                    ImageName               = "LiteTouchTest X64"
                    # ExtraDirectory          = "PEExtraFiles"
                    # BackgroundFile          = "PEExtraFiles\WinPEBackground.bmp"
                    LiteTouchWIMDescription = "Otherdomain Deployment"
                    FeaturePacks            = "winpe-dismcmdlets,winpe-mdac,winpe-netfx,winpe-powershell,winpe-storagewmi"
                }
            )
        }

    ); 
}