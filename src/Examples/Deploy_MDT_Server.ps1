Function Get-ConfigurationDataAsObject {
    [CmdletBinding()]
    [OutputType([hashtable])]
    Param (
        [Parameter(Mandatory)]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformation()]
        [hashtable] $ConfigurationData    
    )
    return $ConfigurationData
}

Configuration DeployMDTServerContract
{
    Param(
        [PSCredential]
        $Credentials
    )

    #NOTE: Every Module must be constant, DSC Bug?!
    Import-DscResource �ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xSmbShare -ModuleVersion 1.1.0.0
    Import-DscResource -ModuleName cNtfsAccessControl -ModuleVersion 1.3.1
    Import-DscResource -ModuleName cMDT -ModuleVersion 1.0.1.0

    node $AllNodes.Where{$_.Role -match "MDT Server"}.NodeName
    {

        $SecurePassword = ConvertTo-SecureString $Node.MDTLocalPassword -AsPlainText -Force
        $UserName = $Node.MDTLocalAccount
        $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword

        [string]$separator = ""
        [bool]$weblink = $false
        If ($Node.SourcePath -like "*/*") { $weblink = $true }

        LocalConfigurationManager {
            RebootNodeIfNeeded = $AllNodes.RebootNodeIfNeeded
            ConfigurationMode  = $AllNodes.ConfigurationMode   
        }

        ForEach ($Key in $Node.MDTInstallationSoftware.Keys) {
            $fileName = ($Node.MDTInstallationSoftware.$Key.SourcePath).Split("/")[-1]
            cMDTPreReqs $Key {
                Ensure       = $Node.MDTInstallationSoftware.$Key.Ensure        
                Name         = $Node.MDTInstallationSoftware.$Key.Name
                ProductId    = $Node.MDTInstallationSoftware.$Key.ProductId
                SourcePath   = $Node.MDTInstallationSoftware.$Key.SourcePath
                DownloadPath = "$($Node.TempLocation)\$($Node.MDTInstallationSoftware.$Key.DownloadPath)\$($fileName)"
            }
        }


        User MDTAccessAccount {
            Ensure                 = "Present"
            UserName               = $Node.MDTLocalAccount
            FullName               = $Node.MDTLocalAccount
            Password               = $Credentials
            PasswordChangeRequired = $false
            PasswordNeverExpires   = $true
            Description            = "Managed Client Administrator Account"
            Disabled               = $false
        }

        WindowsFeature NET35 {
            Ensure = "Present"
            Name   = "Net-Framework-Core"
        }

        Package ADK {
            Ensure     = $Node.MDTInstallationSoftware.ADK.Ensure
            Name       = $Node.MDTInstallationSoftware.ADK.Name
            Path       = "$($Node.TempLocation)\Windows Assessment and Deployment Kit\adksetup.exe"
            ProductId  = $Node.MDTInstallationSoftware.ADK.ProductId
            Arguments  = "/quiet /installpath d:\ADK /features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment"
            ReturnCode = 0
        }

        Package MDT {
            Ensure     = $Node.MDTInstallationSoftware.MDT.Ensure
            Name       = $Node.MDTInstallationSoftware.MDT.Name
            Path       = "$($Node.TempLocation)\Microsoft Deployment Toolkit\MicrosoftDeploymentToolkit_x64.msi"
            ProductId  = $Node.MDTInstallationSoftware.MDT.ProductId
            ReturnCode = 0
        }

        Service BITS {
            Name        = "BITS"
            State       = "Running"
            StartUpType = "Automatic"
        }

        cMDTDirectory TempFolder {
            Ensure = "Present"
            Name   = $Node.TempLocation.Replace("$($Node.TempLocation.Substring(0,2))\", "")
            Path   = $Node.TempLocation.Substring(0, 2)
        }


        cMDTDirectory DeploymentFolder {
            Ensure    = "Present"
            Name      = $Node.PSDrivePath.Replace("$($Node.PSDrivePath.Substring(0,2))\", "")
            Path      = $Node.PSDrivePath.Substring(0, 2)
            DependsOn = "[Package]MDT"
        }

        xSmbShare FolderDeploymentShare {
            Ensure                = "Present"
            Name                  = $Node.PSDriveShareName
            Path                  = $Node.PSDrivePath
            FullAccess            = "$env:COMPUTERNAME\$($Node.MDTLocalAccount)"
            FolderEnumerationMode = "AccessBased"
            DependsOn             = "[cMDTDirectory]DeploymentFolder"
        }

        cNtfsPermissionEntry AssignPermissions {
            Ensure                   = "Present"
            Path                     = $Node.PSDrivePath
            Principal                = "$env:COMPUTERNAME\$($Node.MDTLocalAccount)"
            AccessControlInformation = @(
                cNtfsAccessControlInformation {
                    AccessControlType  = "Allow"
                    FileSystemRights   = "FullControl"
                    Inheritance        = "ThisFolderSubfoldersAndFiles"
                    NoPropagateInherit = $false
                }
            )
            DependsOn                = "[cMDTDirectory]DeploymentFolder"
        }

        File CustomUnattendXml {
            Ensure          = "Present"
            Type            = "File"
            SourcePath      = "D:\Sources\FKUnattend.xml"
            DestinationPath = "D:\DeploymentShare\Scripts"
        }

        cMDTPersistentDrive DeploymentPSDrive {
            Ensure      = "Present"
            Name        = $Node.PSDriveName
            Path        = $Node.PSDrivePath
            Description = $Node.PSDrivePath.Replace("$($Node.PSDrivePath.Substring(0,2))\", "")
            NetworkPath = "\\$($env:COMPUTERNAME)\$($Node.PSDriveShareName)"
            DependsOn   = "[cMDTDirectory]DeploymentFolder"
        }

        cMDTSettings DeploymentSettings {
            Ensure          = "Present"
            Description     = "FK Build"
            Comments        = "FK Build Server 2016"
            EnableMulticast = $false
            SupportX86      = $false
            SupportX64      = $true
            PSDriveName     = $Node.PSDriveName
            PSDrivePath     = $Node.PSDrivePath
            DependsOn       = "[cMDTDirectory]DeploymentFolder"
        }

        ForEach ($SelectionProfile in $Node.SelectionProfiles) {
            cMDTDirectory "SP$($SelectionProfile.Replace(' ',''))" {
                Ensure      = "Present"
                Name        = $SelectionProfile
                Path        = "$($Node.PSDriveName):\Selection Profiles"
                PSDriveName = $Node.PSDriveName
                PSDrivePath = $Node.PSDrivePath
                DependsOn   = "[cMDTDirectory]DeploymentFolder"
            }
        }                
        ForEach ($OperatingSystem in $Node.OperatingSystems) {

            [string]$SourcePath = $OperatingSystem.SourcePath
            If (-not(($SourcePath -like "*:*") -or ($SourcePath -like "*\\*"))) {
                If ($weblink) { $SourcePath = "$($Node.SourcePath)$($SourcePath.Replace("\","/"))" }
                Else { $SourcePath = "$($Node.SourcePath)$($SourcePath.Replace("/","\"))" }
            }

            cMDTOperatingSystem $OperatingSystem.Name.Replace(' ', '') {
                Ensure       = $OperatingSystem.Ensure
                Name         = $OperatingSystem.Name
                Version      = $OperatingSystem.Version
                Path         = "$($Node.PSDriveName):$($OperatingSystem.Path)"
                SourcePath   = $SourcePath
                PSDriveName  = $Node.PSDriveName
                PSDrivePath  = $Node.PSDrivePath
                TempLocation = $Node.TempLocation
                DependsOn    = "[cMDTDirectory]DeploymentFolder"
            }
        }

        ForEach ($TaskSequence in $Node.TaskSequences) {

            cMDTTaskSequence $TaskSequence.Name.Replace(' ', '') {
                Ensure              = $TaskSequence.Ensure
                Name                = $TaskSequence.Name
                Path                = $TaskSequence.Path
                OperatingSystemPath = $TaskSequence.OperatingSystemPath
                WIMFileName         = $TaskSequence.WIMFileName
                ID                  = $TaskSequence.ID
                Template            = $TaskSequence.Template
                OrgName             = $TaskSequence.OrgName
                PSDriveName         = $Node.PSDriveName
                PSDrivePath         = $Node.PSDrivePath
                DependsOn           = "[cMDTOperatingSystem]$($Node.OperatingSystems.Where{$_.SourcePath -like "*$($TaskSequence.WIMFileName)"}.Name.Replace(' ',''))"
            }
        }

        ForEach ($Driver in $Node.Drivers) {

            [string]$SourcePath = $Driver.SourcePath
            If (-not(($SourcePath -like "*:*") -or ($SourcePath -like "*\\*"))) {
                If ($weblink) { $SourcePath = "$($Node.SourcePath)$($SourcePath.Replace("\","/"))" }
                Else { $SourcePath = "$($Node.SourcePath)$($SourcePath.Replace("/","\"))" }
            }

            cMDTDriver $Driver.Name.Replace(' ', '') {
                Ensure       = $Driver.Ensure
                Name         = $Driver.Name
                Version      = $Driver.Version
                Path         = "$($Node.PSDriveName):$($Driver.Path)"
                SourcePath   = $SourcePath
                Comment      = $Driver.Comment
                Enabled      = "True"
                PSDriveName  = $Node.PSDriveName
                PSDrivePath  = $Node.PSDrivePath
                TempLocation = $Node.TempLocation
                DependsOn    = "[cMDTDirectory]DeploymentFolder"
            }
        }

        ForEach ($Application in $Node.Applications) {

            [string]$ApplicationSourcePath = $Application.ApplicationSourcePath
            If (-not(($ApplicationSourcePath -like "*:*") -or ($ApplicationSourcePath -like "*\\*"))) {
                If ($weblink) { $ApplicationSourcePath = "$($Node.SourcePath)$($ApplicationSourcePath.Replace("\","/"))" }
                Else { $ApplicationSourcePath = "$($Node.SourcePath)$($ApplicationSourcePath.Replace("/","\"))" }
            }

            cMDTApplication $Application.Name.Replace(' ', '') {
                Ensure                = $Application.Ensure
                Name                  = $Application.Name
                Version               = $Application.Version
                Path                  = "$($Node.PSDriveName):$($Application.Path)"
                ShortName             = $Application.ShortName
                Publisher             = $Application.Publisher
                Language              = $Application.Language
                CommandLine           = $Application.CommandLine
                WorkingDirectory      = $Application.WorkingDirectory
                ApplicationSourcePath = $ApplicationSourcePath
                DestinationFolder     = $Application.DestinationFolder
                Enabled               = "True"
                PSDriveName           = $Node.PSDriveName
                PSDrivePath           = $Node.PSDrivePath
                TempLocation          = $Node.TempLocation
                DependsOn             = "[cMDTDirectory]DeploymentFolder"
            }
        }

        <# foreach ($Application in $Node.ApplicationsNoSource) 
        {
            cMDTApplicationNoSource $Application.Name.Replace(' ', '') 
            {
                Ensure                = $Application.Ensure
                Name                  = $Application.Name
                Version               = $Application.Version
                Comments              = $Application.Comments
                Path                  = $Application.Path
                ShortName             = $Application.ShortName
                Publisher             = $Application.Publisher
                Language              = $Application.Language
                CommandLine           = $Application.CommandLine
                WorkingDirectory      = $Application.WorkingDirectory
                Enable                = $Application.Enable
                PSDriveName           = $Node.PSDriveName
                PSDrivePath           = $Node.PSDrivePath
                Debug                 = $true
                DependsOn             = "[cMDTDirectory]DeploymentFolder"
            }
        } #>

        foreach ($item in $Node.TaskSequenceCustomize) {
            cMDTTaskSequenceCustomize "TSCustomize_$($item.Name.Replace(' ', ''))" {
                TSFile                  = $item.TSFile
                Type                    = $item.Type
                Name                    = $item.Name
                Description             = $item.Description
                Path                    = $item.Path
                Command                 = $item.Command
                StartIn                 = $item.StartIn
                RunAsUser               = $item.RunAsUser
                CommandLineUserName     = $item.CommandLineUserName
                CommandLineUserPassword = $item.CommandLineUserPassword
                LoadProfile             = $item.LoadProfile
                SuccessCodeList         = $item.SuccessCodeList
                TSVariableName          = $item.TSVariableName
                TSVariableValue         = $item.TSVariableValue
                PSDrivePath             = $Node.PSDrivePath
                PSDriveName             = $Node.PSDriveName
                DependsOn               = "[cMDTTaskSequence]$($Node.TaskSequences.Where{ $_.ID -eq $item.TSFile.Split("\")[-2]}.Name.Replace(' ', ''))"
            }
        }

        foreach ($step in $Node.TaskSequenceModifyStep) {

            cMDTTaskSequenceModifyStep "TSModifyStep_$($step.Name.Replace(' ', ''))" {
                TSFile          = $step.TSFile
                Name            = $step.Name
                Path            = $step.Path
                Disable         = $step.Disable
                ContinueOnError = $step.ContinueOnError
                SuccessCodeList = $step.SuccessCodeList
                Description     = $step.Description
                StartIn         = $step.StartIn
                DependsOn       = "[cMDTTaskSequence]$($Node.TaskSequences.Where{ $_.ID -eq $step.TSFile.Split("\")[-2]}.Name.Replace(' ', ''))"
            }
        }

        ForEach ($CustomSetting in $Node.CustomSettings) {

            If ($Node.SourcePath -like "*/*") { $weblink = $true }

            [string]$SourcePath = $CustomSetting.SourcePath
            If (-not(($SourcePath -like "*:*") -or ($SourcePath -like "*\\*"))) {
                If ($weblink) { $SourcePath = "$($Node.SourcePath)$($SourcePath.Replace("\","/"))" }
                Else { $SourcePath = "$($Node.SourcePath)$($SourcePath.Replace("/","\"))" }
            }

            cMDTCustomize $CustomSetting.Name.Replace(' ', '') {
                Ensure       = $CustomSetting.Ensure
                Name         = $CustomSetting.Name
                Version      = $CustomSetting.Version
                SourcePath   = $SourcePath
                Path         = $Node.PSDrivePath
                TempLocation = $Node.TempLocation
                #Protected           = $Protected
                DependsOn    = "[cMDTDirectory]DeploymentFolder"
            }
        }        
        ForEach ($IniFile in $Node.CustomizeIniFiles) {

            If ($IniFile.Name -eq "CustomSettingsIni") {

                If ($IniFile.HomePage) { 
                    $HomePage = "Home_Page=$($IniFile.HomePage)" 
                }
                Else { $HomePage = ";Home_Page=" }

                If ($IniFile.SkipAdminPassword) { $SkipAdminPassword = "SkipAdminPassword=$($IniFile.SkipAdminPassword)" }              Else { $SkipAdminPassword = ";SkipAdminPassword=" }
                If ($IniFile.SkipApplications) { $SkipApplications = "SkipApplications=$($IniFile.SkipApplications)" }                  Else { $SkipApplications = ";SkipApplications=" }
                If ($IniFile.SkipBitLocker) { $SkipBitLocker = "SkipBitLocker=$($IniFile.SkipBitLocker)" }                              Else { $SkipBitLocker = ";SkipBitLocker=" }
                If ($IniFile.SkipCapture) { $SkipCapture = "SkipCapture=$($IniFile.SkipCapture)" }                                      Else { $SkipCapture = ";SkipCapture=" }
                If ($IniFile.SkipComputerBackup) { $SkipComputerBackup = "SkipComputerBackup=$($IniFile.SkipComputerBackup)" }          Else { $SkipComputerBackup = ";SkipComputerBackup=" }
                If ($IniFile.SkipComputerName) { $SkipComputerName = "SkipComputerName=$($IniFile.SkipComputerName)" }                  Else { $SkipComputerName = ";SkipComputerName=" }
                If ($IniFile.SkipDomainMembership) { $SkipDomainMembership = "SkipDomainMembership=$($IniFile.SkipDomainMembership)" }  Else { $SkipDomainMembership = ";SkipDomainMembership=" }
                If ($IniFile.SkipFinalSummary) { $SkipFinalSummary = "SkipFinalSummary=$($IniFile.SkipFinalSummary)" }                  Else { $SkipFinalSummary = ";SkipFinalSummary=" }
                If ($IniFile.SkipLocaleSelection) { $SkipLocaleSelection = "SkipLocaleSelection=$($IniFile.SkipLocaleSelection)" }      Else { $SkipLocaleSelection = ";SkipLocaleSelection=" }
                If ($IniFile.SkipPackageDisplay) { $SkipPackageDisplay = "SkipPackageDisplay=$($IniFile.SkipPackageDisplay)" }          Else { $SkipPackageDisplay = ";SkipPackageDisplay=" }
                If ($IniFile.SkipProductKey) { $SkipProductKey = "SkipProductKey=$($IniFile.SkipProductKey)" }                          Else { $SkipProductKey = ";SkipProductKey=" }
                If ($IniFile.SkipRoles) { $SkipRoles = "SkipRoles=$($IniFile.SkipRoles)" }                                              Else { $SkipRoles = ";SkipRoles=" }
                If ($IniFile.SkipSummary) { $SkipSummary = "SkipSummary=$($IniFile.SkipSummary)" }                                      Else { $SkipSummary = ";SkipSummary=" }
                If ($IniFile.SkipTimeZone) { $SkipTimeZone = "SkipTimeZone=$($IniFile.SkipTimeZone)" }                                  Else { $SkipTimeZone = ";SkipTimeZone=" }
                If ($IniFile.SkipUserData) { $SkipUserData = "SkipUserData=$($IniFile.SkipUserData)" }                                  Else { $SkipUserData = ";SkipUserData=" }
                If ($IniFile.SkipTaskSequence) { $SkipTaskSequence = "SkipTaskSequence=$($IniFile.SkipTaskSequence)" }                  Else { $SkipTaskSequence = ";SkipTaskSequence=" }
                If ($IniFile.JoinDomain) { $JoinDomain = "JoinDomain=$($IniFile.JoinDomain)" }                                          Else { $JoinDomain = ";JoinDomain=" }
                If ($IniFile.DomainAdmin) { $DomainAdmin = "DomainAdmin=$($IniFile.DomainAdmin)" }                                      Else { $DomainAdmin = ";DomainAdmin=" }
                If ($IniFile.DomainAdminDomain) { $DomainAdminDomain = "DomainAdminDomain=$($IniFile.DomainAdminDomain)" }              Else { $DomainAdminDomain = ";DomainAdminDomain=" }
                If ($IniFile.DomainAdminPassword) { $DomainAdminPassword = "DomainAdminPassword=$($IniFile.DomainAdminPassword)" }      Else { $DomainAdminPassword = ";DomainAdminPassword=" }
                If ($IniFile.MachineObjectOU) { $MachineObjectOU = "MachineObjectOU=$($IniFile.MachineObjectOU)" }                      Else { $MachineObjectOU = ";MachineObjectOU=" }
                If ($IniFile.TimeZoneName) { $TimeZoneName = "TimeZoneName=$($IniFile.TimeZoneName)" }                                  Else { $TimeZoneName = ";TimeZoneName=" }
                If ($IniFile.WSUSServer) { $WSUSServer = "WSUSServer=$($IniFile.WSUSServer)" }                                          Else { $WSUSServer = ";WSUSServer=" }
                If ($IniFile.UserLocale) { $UserLocale = "UserLocale=$($IniFile.UserLocale)" }                                          Else { $UserLocale = ";UserLocale=" }
                If ($IniFile.KeyboardLocale) { $KeyboardLocale = "KeyboardLocale=$($IniFile.KeyboardLocale)" }                          Else { $KeyboardLocale = ";KeyboardLocale=" }
                If ($IniFile.UILanguage) { $UILanguage = "UILanguage=$($IniFile.UILanguage)" }                                          Else { $UILanguage = ";UILanguage=" }
                If ($IniFile.ProductKey) { $ProductKey = "ProductKey=$($IniFile.ProductKey)" }                                          Else { $ProductKey = ";ProductKey=" }
                If ($IniFile.EventService) { $EventService = "EventService=$($IniFile.EventService)" }                                  Else { $EventService = ";EventService=" }

                cMDTCustomSettingsIni ini {
                    Ensure    = $IniFile.Ensure
                    Path      = "$($Node.PSDrivePath)\$($IniFile.Path)"
                    DependsOn = "[cMDTDirectory]DeploymentFolder"
                    Content   = @"
[Settings]
Priority=MacAddress,Default

[Default]
OSInstall=Y
_SMSTSORGNAME=FK Windows 2016 Build
HideShell=YES
DisableTaskMgr=YES
ApplyGPOPack=NO
UserDataLocation=NONE
JoinWorkgroup=WORKGROUP

;Local admin password
AdminPassword=$($Node.LocalAdminPassword)
SLShare=%DeployRoot%\Logs
$($EventService)

DoCapture=SYSPREP
FinishAction=SHUTDOWN
SkipFinalSummary=YES

OrgName=FK
$($HomePage)

;Enable or disable options:
$($SkipAdminPassword)
$($SkipApplications)
$($SkipBitLocker)
$($SkipCapture)
$($SkipComputerBackup)
$($SkipComputerName)
$($SkipDomainMembership)
$($SkipFinalSummary)
$($SkipLocaleSelection)
$($SkipPackageDisplay)
$($SkipProductKey)
$($SkipRoles)
$($SkipSummary)
$($SkipTimeZone)
$($SkipUserData)
$($SkipTaskSequence)
$($ProductKey)

;TimeZone settings
$($TimeZoneName)

$($WSUSServer)

;Example keyboard layout.
$($UserLocale)
$($KeyboardLocale)
$($UILanguage)

[00:50:56:ba:32:12]
TaskSequenceID=REF-S16-X64-001
SkipWizard=YES

"@
                }

            }

            If ($IniFile.Name -eq "BootstrapIni") {

                If ($IniFile.DeployRoot) { $DeployRoot = "DeployRoot=\\$($env:COMPUTERNAME)$($IniFile.DeployRoot)" } Else { $DeployRoot = ";DeployRoot=" }
                If ($IniFile.KeyboardLocalePE) { $KeyboardLocalePE = "KeyboardLocalePE=$($IniFile.KeyboardLocalePE)" }         Else { $KeyboardLocalePE = ";KeyboardLocalePE=" }

                cMDTBootstrapIni ini {
                    Ensure    = $IniFile.Ensure
                    Path      = "$($Node.PSDrivePath)\$($IniFile.Path)"
                    DependsOn = "[cMDTDirectory]DeploymentFolder"
                    Content   = @"
[Settings]
Priority=Default

[Default]
$($DeployRoot)
SkipBDDWelcome=YES

;MDT Connect Account
UserID=$($Node.MDTLocalAccount)
UserPassword=$($Node.MDTLocalPassword)
UserDomain=$($env:COMPUTERNAME)

;Keyboard Layout
$($KeyboardLocalePE)
"@
                }
            }

        }

        ForEach ($Image in $Node.BootImage) {

            cMDTUpdateBootImage updateBootImage {
                Version                 = $Image.Version
                PSDeploymentShare       = $Node.PSDriveName
                Force                   = $true
                Compress                = $true
                DeploymentSharePath     = $Node.PSDrivePath
                ExtraDirectory          = $Image.ExtraDirectory
                BackgroundFile          = $Image.BackgroundFile
                LiteTouchWIMDescription = $Image.LiteTouchWIMDescription
                FeaturePacks            = $Image.FeaturePacks
                GenerateLiteTouchISO    = $true
                DependsOn               = "[cMDTDirectory]DeploymentFolder"
            }
        }
    }
}


#Get configuration data
[hashtable]$ConfigurationData = Get-ConfigurationDataAsObject -ConfigurationData "$PSScriptRoot\Deploy_MDT_Server_ConfigurationData.psd1"

#Create DSC MOF job
DeployMDTServerContract -OutputPath "$PSScriptRoot\MDT-Deploy_MDT_Server" -ConfigurationData $ConfigurationData

#Set DSC LocalConfigurationManager
Set-DscLocalConfigurationManager -Path "$PSScriptRoot\MDT-Deploy_MDT_Server" -Verbose

#Start DSC MOF job
Start-DscConfiguration -Wait -Force -Verbose -ComputerName "$env:computername" -Path "$PSScriptRoot\MDT-Deploy_MDT_Server"

Write-Output ""
Write-Output "FK Deploy MDT Server Builder completed!"

