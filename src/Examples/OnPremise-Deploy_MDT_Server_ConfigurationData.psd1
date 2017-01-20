# For instructions of how to edit this file and detailed usage of the module
# open your prefered Internet browser and use the following link:
# https://github.com/ServiceDudes/cMDT

@{
    AllNodes = 
    @(
        @{

            #Global Settings for the configuration of Desired State Local Configuration Manager:
            NodeName                    = "*"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
            RebootNodeIfNeeded          = $true            ConfigurationMode           = "ApplyAndAutoCorrect"      

        },


        @{

            #Node Settings for the configuration of an MDT Server.
            NodeName           = "$env:computername"
            Role               = "MDT Server"

            #SMB or web link to a pull server
            SourcePath         = "C:\Sources"

            #Local account to create for MDT. Used for making the connection to the deployment share.
            MDTLocalAccount    = "SVCMDTConnect001"
            MDTLocalPassword   = "ChangeMe1!"

            #Local administrator password on deployed clients.
            LocalAdminPassword   = "ChangeMe1!"

            #Download and extraction temporary folder
            TempLocation       = "C:\Temp"

            #MDT deoployment share paths
            PSDriveName        = "DS001"
            PSDrivePath        = "C:\DeploymentShare"

            #SMB share name for the deployment share. 
            PSDriveShareName   = "DeploymentShare$"
            
            #Selection profile creation
            SelectionProfiles  = @("WinPE x86","WinPE x64")

            #MDT Software installation prerequisites
            MDTInstallationSoftware   = @{
                ADK                   = @(
                    @{                
                        Ensure        = "Present"
                        Name          = "Windows Assessment and Deployment Kit - Windows 10"
                        ProductId     = "62D8BE3F-BC1C-D0AF-2D20-724A7A8CFC3B"
                        SourcePath    = "http://download.microsoft.com/download/3/8/B/38BBCA6A-ADC9-4245-BCD8-DAA136F63C8B/adk/adksetup.exe"
                        DownloadPath  = "Windows Assessment and Deployment Kit"
                    }
                )
                MDT                   = @(
                    @{  
                        Ensure        = "Present"
                        Name          = "Microsoft Deployment Toolkit (6.3.8443.1000)"
                        ProductId     = "9547DE37-4A70-4194-97EA-ACC3E747254B"
                        SourcePath    = "https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi"
                        DownloadPath  = "Microsoft Deployment Toolkit"
                    }
                )
                C01                   = @(
                    @{  
                        Ensure        = "Present"
                        Name          = "modelalias"
                        SourcePath    = "http://deploymentresearch.com/mnfiles/modelalias.zip"
                        DownloadPath  = "Community\Scripts"
                    }
                )
            }

            #Operating systems to import to MDT
            OperatingSystems   = @(
                @{  
                    Ensure     = "Present"
                    Name       = "Windows 10 Enterprise x64"
                    Version    = "1.0.0.0"
                    Path       = "\Operating Systems\Windows 10"
                    SourcePath =  "\Install"
                }
            )

            #Task sqeuences; are dependent on imported Operating system in MDT
            TaskSequences   = @(
                @{  
                    Ensure      = "Present"
                    Name        = "Windows 10 Enterprise x64"
                    Path        = "\Task Sequences\Windows 10"
                    WIMFileName = "install"
                    ID          = "DEP-W10-X64-001"
                }
            )

            #Specific task sequence steps
            TaskSequenceSetVariableSteps = @(
                @{
                    Ensure                      = "Present"
                    TaskSequenceId              = "DEP-W10-X64-001"
                    TaskSequenceParentGroupName = "Preinstall"
                    InsertAfterStep             = "Enable BitLocker (Offline)"
                    TaskSequenceVariableName    = "DriverGroup001"
                    TaskSequenceVariableValue   = "Windows 10 x64\%Make%\%ModelAlias%"
                    TaskSequenceStepName        = "Set Drivergroup001"
                    TaskSequenceStepDescription = "This is a test description"
                    Disable                     = $false
                    ContinueOnError             = $false
                    SuccessCodeList             = "0 3010"
                }
            )
            <#
            #Drivers to import
            Drivers   = @(
                @{  
                    Ensure     = "Present"
                    Name       = "HPElitebookG1840"
                    Version    = "1.0.0.0"
                    Path       = "\Out-of-Box Drivers\Windows 10 x64\HP"
                    SourcePath = "\HPElitebookG1840"
                    Comment    = "Drivers for Win10 for HP Elitebook G1 840"
                }
            )

            Applications   = @(
                @{  
                    Ensure                = "Present"
                    Name                  = "PortQryUI"
                    Version               = "1.0.0.0"
                    Path                  = "\Applications\Common Applications\Desktop"
                    ShortName             = "PortQryUI"
                    Publisher             = "PortQryUI"
                    Language              = "en-US"
                    CommandLine           = "PortQryUI.exe"
                    WorkingDirectory      = ".\"
                    ApplicationSourcePath = "https://web.url/PortQryUI"
                    DestinationFolder     = "Common Applications\Desktop\PortQryUI"
                }
            )

            #Application bundles to create
            ApplicationBundles   = @(
                @{  
                    Ensure              = "Present"
                    BundleName          = "DeveloperApps"
                    BundledApplications = @('seven-z-1514-x64_1.0.0.0')
                    Version             = "1.0.0.0"
                    Publisher           = "7-Zip"
                    Language            = "en-US"
                    Hide                = $false
                    Enable              = $true
                    Folder              = "Applications"
                }               
            )
            #>

            #Custom folder/files to add to the MDT
            CustomSettings   = @(
                @{  
                    Ensure     = "Present"
                    Name       = "PEExtraFiles"
                    Version    = "1.0.0.0"
                    SourcePath = "\PEExtraFiles"
                }
                @{  
                    Ensure     = "Present"
                    Name       = "Scripts"
                    Version    = "1.0.0.0"
                    SourcePath = "\Scripts"
                    Protected  = $true
                }
            )

            #Custom settings and boot ini file management
            CustomizeIniFiles  = @(
                @{  
                    Ensure               = "Present"
                    Name                 = "CustomSettingsIni"
                    Path                 = "\Control\CustomSettings.ini"
                    HomePage             = "http://www.otherdomain.com"
                    SkipAdminPassword    = "NO"
                    SkipApplications     = "NO"
                    SkipBitLocker        = "NO"
                    SkipCapture          = "YES"
                    SkipComputerBackup   = "YES"
                    SkipComputerName     = "NO"
                    SkipDomainMembership = "NO"
                    SkipFinalSummary     = "NO"
                    SkipLocaleSelection  = "NO"
                    SkipPackageDisplay   = "YES"
                    SkipProductKey       = "YES"
                    SkipRoles            = "YES"
                    SkipSummary          = "NO"
                    SkipTimeZone         = "NO"
                    SkipUserData         = "YES"
                    SkipTaskSequence     = "NO"
                    JoinDomain           = "ads.otherdomain.com"
                    DomainAdmin          = "MDTDomJoinAccount"
                    DomainAdminDomain    = "ads.otherdomain.com"
                    DomainAdminPassword  = "ChangeMe1!"
                    MachineObjectOU      = "OU=Win10-Prod,OU=Clients,OU=Container,DC=ads,DC=otherdomain,DC=com"
                    TimeZoneName         = "W. Europe Standard Time"
                    WSUSServer           = ""
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
            BootImage  = @(
                @{  
                    Ensure                  = "Present"
                    Version                 = "1.0.0.0"
                    Path                    = "\Boot\LiteTouchPE_x64.wim"
                    ImageName               = "LiteTouchTest X64"
                    ExtraDirectory          = "PEExtraFiles"
                    BackgroundFile          = "PEExtraFiles\WinPEBackground.bmp"
                    LiteTouchWIMDescription = "Otherdomain Deployment"
                    FeaturePacks            = "winpe-dismcmdlets,winpe-mdac,winpe-netfx,winpe-powershell,winpe-storagewmi"
                }
            )
        }

    ); 
}