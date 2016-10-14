$ConfigurationData = Invoke-Expression (Get-Content -Path "C:\Repo\ManagedClient\Modules\cMDT\cMDT\Examples\Deploy_MDT_Server_ConfigurationData.psd1" -Raw)

ForEach ($Node in $ConfigurationData.AllNodes)
{

    ForEach ($IniFile in $Node.CustomizeIniFiles)   
    {
        
        If ($IniFile.Name -eq "CustomSettingsIni")
        {

        If ($IniFile.HomePage)             { $HomePage             = "Home_Page=$($IniFile.HomePage)" }                        Else { $HomePage             = ";Home_Page=" }
        If ($IniFile.SkipAdminPassword)    { $SkipAdminPassword    = "SkipAdminPassword=$($IniFile.SkipAdminPassword)" }       Else { $SkipAdminPassword    = ";SkipAdminPassword=" }
        If ($IniFile.SkipApplications)     { $SkipApplications     = "SkipApplications=$($IniFile.SkipApplications)" }         Else { $SkipApplications     = ";SkipApplications=" }
        If ($IniFile.SkipBitLocker)        { $SkipBitLocker        = "SkipBitLocker=$($IniFile.SkipBitLocker)" }               Else { $SkipBitLocker        = ";SkipBitLocker=" }
        If ($IniFile.SkipCapture)          { $SkipCapture          = "SkipCapture=$($IniFile.SkipCapture)" }                   Else { $SkipCapture          = ";SkipCapture=" }
        If ($IniFile.SkipComputerBackup)   { $SkipComputerBackup   = "SkipComputerBackup=$($IniFile.SkipComputerBackup)" }     Else { $SkipComputerBackup   = ";SkipComputerBackup=" }
        If ($IniFile.SkipComputerName)     { $SkipComputerName     = "SkipComputerName=$($IniFile.SkipComputerName)" }         Else { $SkipComputerName     = ";SkipComputerName=" }
        If ($IniFile.SkipDomainMembership) { $SkipDomainMembership = "SkipDomainMembership=$($IniFile.SkipDomainMembership)" } Else { $SkipDomainMembership = ";SkipDomainMembership=" }
        If ($IniFile.SkipFinalSummary)     { $SkipFinalSummary     = "SkipFinalSummary=$($IniFile.SkipFinalSummary)" }         Else { $SkipFinalSummary     = ";SkipFinalSummary=" }
        If ($IniFile.SkipLocaleSelection)  { $SkipLocaleSelection  = "SkipLocaleSelection=$($IniFile.SkipLocaleSelection)" }   Else { $SkipLocaleSelection  = ";SkipLocaleSelection=" }
        If ($IniFile.SkipPackageDisplay)   { $SkipPackageDisplay   = "SkipPackageDisplay=$($IniFile.SkipPackageDisplay)" }     Else { $SkipPackageDisplay   = ";SkipPackageDisplay=" }
        If ($IniFile.SkipProductKey)       { $SkipProductKey       = "SkipProductKey=$($IniFile.SkipProductKey)" }             Else { $SkipProductKey       = ";SkipProductKey=" }
        If ($IniFile.SkipRoles)            { $SkipRoles            = "SkipRoles=$($IniFile.SkipRoles)" }                       Else { $SkipRoles            = ";SkipRoles=" }
        If ($IniFile.SkipSummary)          { $SkipSummary          = "SkipSummary=$($IniFile.SkipSummary)" }                   Else { $SkipSummary          = ";SkipSummary=" }
        If ($IniFile.SkipTimeZone)         { $SkipTimeZone         = "SkipTimeZone=$($IniFile.SkipTimeZone)" }                 Else { $SkipTimeZone         = ";SkipTimeZone=" }
        If ($IniFile.SkipUserData)         { $SkipUserData         = "SkipUserData=$($IniFile.SkipUserData)" }                 Else { $SkipUserData         = ";SkipUserData=" }
        If ($IniFile.SkipTaskSequence)     { $SkipTaskSequence     = "SkipTaskSequence=$($IniFile.SkipTaskSequence)" }         Else { $SkipTaskSequence     = ";SkipTaskSequence=" }
        If ($IniFile.JoinDomain)           { $JoinDomain           = "JoinDomain=$($IniFile.JoinDomain)" }                     Else { $JoinDomain           = ";JoinDomain=" }
        If ($IniFile.DomainAdmin)          { $DomainAdmin          = "DomainAdmin=$($IniFile.DomainAdmin)" }                   Else { $DomainAdmin          = ";DomainAdmin=" }
        If ($IniFile.DomainAdminDomain)    { $DomainAdminDomain    = "DomainAdminDomain=$($IniFile.DomainAdminDomain)" }       Else { $DomainAdminDomain    = ";DomainAdminDomain=" }
        If ($IniFile.DomainAdminPassword)  { $DomainAdminPassword  = "DomainAdminPassword=$($IniFile.DomainAdminPassword)" }   Else { $DomainAdminPassword  = ";DomainAdminPassword=" }
        If ($IniFile.MachineObjectOU)      { $MachineObjectOU      = "MachineObjectOU=$($IniFile.MachineObjectOU)" }           Else { $MachineObjectOU      = ";MachineObjectOU=" }
        If ($IniFile.TimeZoneName)         { $TimeZoneName         = "TimeZoneName=$($IniFile.TimeZoneName)" }                 Else { $TimeZoneName         = ";TimeZoneName=" }
        If ($IniFile.WSUSServer)           { $WSUSServer           = "WSUSServer=$($IniFile.WSUSServer)" }                     Else { $WSUSServer           = ";WSUSServer=" }
        If ($IniFile.UserLocale)           { $UserLocale           = "UserLocale=$($IniFile.UserLocale)" }                     Else { $UserLocale           = ";UserLocale=" }
        If ($IniFile.KeyboardLocale)       { $KeyboardLocale       = "KeyboardLocale=$($IniFile.KeyboardLocale)" }             Else { $KeyboardLocale       = ";KeyboardLocale=" }
        If ($IniFile.UILanguage)           { $UILanguage           = "UILanguage=$($IniFile.UILanguage)" }                     Else { $UILanguage           = ";UILanguage=" }
        If ($IniFile.KeyboardLocalePE)     { $KeyboardLocalePE     = "KeyboardLocalePE=$($IniFile.KeyboardLocalePE)" }         Else { $KeyboardLocalePE     = ";KeyboardLocalePE=" }
        If ($IniFile.ProductKey)           { $ProductKey           = "ProductKey=$($IniFile.ProductKey)" }                     Else { $ProductKey           = ";ProductKey=" }
        If ($IniFile.EventService)         { $EventService         = "EventService=$($IniFile.EventService)" }                 Else { $ProductKey           = ";EventService=" }

        $Content   = @"
$($Node.NodeName)
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
AdminPassword=$($Node.LocalAdminPassword)
SLShare=%DeployRoot%\Logs
$($EventService)

OrgName=Company
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

;DomainJoin
$($JoinDomain)
$($DomainAdmin)
$($DomainAdminDomain)
$($DomainAdminPassword)
$($MachineObjectOU)

;TimeZone settings
$($TimeZoneName)

$($WSUSServer)

;Example keyboard layout.
$($UserLocale)
$($KeyboardLocale)
$($UILanguage)

;Drivers
DriverSelectionProfile=Nothing

;DriverInjectionMode=ALL

FinishAction=RESTART
"@

        Set-Content "C:\Repo\ManagedClient\Modules\cMDT\cMDT\Examples\Test.txt" $Content

        }

    }

}