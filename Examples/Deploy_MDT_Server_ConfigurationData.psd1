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
            RebootNodeIfNeeded          = $true            ConfigurationMode           = "ApplyAndAutoCorrect"      

        },


        @{

            #Node Settings for the configuration of an MDT Server:
            NodeName           = "$env:computername"
            Role               = "MDT Server"

            #SMB or web link to a pull server
            SourcePath         = "c:\Sources"

            #Local account to create for MDT
            MDTLocalAccount    = "SVCMDTConnect001"
            MDTLocalPassword   = "P@ssW0rD!"

            #Client local administrator password on client
            LocalAdminPassword   = "P@ssW0rD!"

            #Download and extraction temporary folder
            TempLocation       = "C:\Temp"

            #MDT deoployment share paths
            PSDriveName        = "DS001"
            PSDrivePath        = "C:\DeploymentShare"

            #SMB share name
            PSDriveShareName   = "DeploymentShare$"

            #Operating system MDT directory information
            OSDirectories   = @(
                @{  
                    Ensure = "Present"
                    OperatingSystem = "Windows 10"
                }
            )

            #Driver vendor MDT information
            Vendors   = @(
                @{  
                    Ensure = "Present"
                    Vendor = "Dell Inc."
                }
                @{  
                    Ensure = "Present"
                    Vendor = "Hewlett Packard"
                }
                @{  
                    Ensure = "Present"
                    Vendor = "Lenovo"
                }
            )

            #MDT Application Folder Structure
            ApplicationFolderStructure   = @(
                @{  
                    Ensure = "Present"
                    Folder = "Core Applications"
                    SubFolders   = @(
                        @{  
                            Ensure    = "Present"
                            SubFolder = "Microsoft"
                        }
                        @{  
                            Ensure    = "Present"
                            SubFolder = "Adobe"
                        }
                        @{  
                            Ensure    = "Present"
                            SubFolder = "Apple"
                        }
                    )
                }
                @{  
                    Ensure = "Present"
                    Folder = "Driver Applications"
                    SubFolders   = @(
                        @{  
                            Ensure    = "Present"
                            SubFolder = "Lenovo"
                        }
                    )
                }
                @{  
                    Ensure = "Present"
                    Folder = "Common Applications"
                }
            )

            #Selection profile creation
            SelectionProfiles  = @("WinPE x86","WinPE x64")

            #Operating systems to import to MDT
            OperatingSystems   = @(
                @{  
                    Ensure     = "Present"
                    Name       = "Windows 10 Enterprise x64"
                    Version    = "1.0.0.0"
                    Path       = "\Operating Systems\Windows 10"
                    SourcePath = "/Install"
                }
            )

            #Task sqeuences; are dependent on imported Operating system in MDT
            TaskSequences   = @(
                @{  
                    Ensure      = "Present"
                    Name        = "Windows 10 x64"
                    Path        = "\Task Sequences\Windows 10"
                    WIMFileName = "Install"
                    ID          = "01"
                }
            )

            <#
            #Drivers to import
            Drivers   = @(
                @{  
                    Ensure     = "Present"
                    Name       = "Latitude 3340"
                    Version    = "6.0.1.6070_A00"
                    Path       = "\Out-of-Box Drivers\Windows 10 x64\Dell Inc."
                    SourcePath = "/Audio_Driver_5P33P_WN32"
                    Comment    = "Drivers for Dell Latitude 3340 Laptops"
                }
            )

            #Applications to import
            Applications   = @(
                @{  
                    Ensure                = "Present"
                    Name                  = "Teamviewer"
                    Version               = "1.0.0.0"
                    Path                  = "\Applications\Common Applications"
                    ShortName             = "Teamviewer"
                    Publisher             = "Teamviewer"
                    Language              = "en-US"
                    CommandLine           = "install.cmd"
                    WorkingDirectory      = ".\"
                    ApplicationSourcePath = "/TeamViewer_Setup_sv"
                    DestinationFolder     = "Common Applications\Teamviewer"
                }
            )
            #>

            #Custom folder/files to add to the MDT
            CustomSettings   = @(
                @{  
                    Ensure     = "Present"
                    Name       = "PEExtraFiles"
                    Version    = "1.0.0.0"
                    SourcePath = "/PEExtraFiles"
                }
                @{  
                    Ensure     = "Present"
                    Name       = "Scripts"
                    Version    = "1.0.0.0"
                    SourcePath = "/Scripts"
                    Protected  = $true
                }
            )

            #Custom settings and boot ini file management
            CustomizeIniFiles  = @(
                @{  
                    Ensure               = "Present"
                    Name                 = "CustomSettingsIni"
                    Path                 = "\Control\CustomSettings.ini"
                    HomePage             = "http://companyURL"
                    SkipAdminPassword    = "NO"
                    SkipApplications     = "YES"
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
                    JoinDomain           = "ad.company.net"
                    DomainAdmin          = "DomainJoinAccount"
                    DomainAdminDomain    = "ad.company.net"
                    DomainAdminPassword  = "DomainJoinAccountPassword"
                    MachineObjectOU      = "OU=Clients,OU=company,DC=ad,DC=company,DC=net"
                    TimeZoneName         = "W. Europe Standard Time"
                    WSUSServer           = "http://fqdn:port"
                    UserLocale           = "en-US"
                    KeyboardLocale       = "en-US"
                    UILanguage           = "en-US"
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
                    Ensure     = "Present"
                    Name       = "BootImage"
                    Version    = "1.0.0.0"
                    Path       = "\Boot\LiteTouchPE_x64.wim"
                    ImageName  = "LiteTouchTest X64"
                    ExtraDirectory = "PEExtraFiles"
                    BackgroundFile = "PEExtraFiles\background.bmp"
                    LiteTouchWIMDescription = "Customer Deployment"
                }
            )
        }

    ); 
}