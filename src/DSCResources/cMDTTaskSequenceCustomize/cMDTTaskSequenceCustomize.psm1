[DscResource()]
class cMDTTaskSequenceCustomize {

    [DscProperty(Key)]
    [string]$TSFile

    [DscProperty(Mandatory)]
    [string]$Type

    [DscProperty(Key)]
    [string]$Name

    [DscProperty()]
    [string]$Description

    [DscProperty(Mandatory)]
    [string]$Path

    [DscProperty()]
    [string]$InsertAfterStep

    [DscProperty()]
    [string]$Command

    [DscProperty()]
    [string]$StartIn

    [DscProperty()]
    [string]$RunAsUser

    [DscProperty()]
    [string]$CommandLineUserName

    [DscProperty()]
    [string]$CommandLineUserPassword

    [DscProperty()]
    [string]$LoadProfile

    [DscProperty()]
    [string]$SuccessCodeList = "0 3010"

    [DscProperty()]
    [string]$TSVariableName

    [DscProperty()]
    [string]$TSVariableValue

    [DscProperty()]
    [string]$PSDriveName

    [DscProperty()]
    [string]$PSDrivePath

    [DscProperty()]
    [string]$OSName

    [DscProperty()]
    [string]$OSRoles

    [DscProperty()]
    [string]$OSRoleServices

    [DscProperty()]
    [string]$OSFeatures

    [DscProperty()]
    [string]$TSPath

    [void] Set() {
        $ts = $this.ReadTaskSequenceXML()

        if (-not $ts) {
            throw "$($this.TSPath) can't be found."
        }

        $query = (Get-NodePathQuery -Path $this.Path)

        $parentGroup = $ts.SelectSingleNode($query)

        $oSIndex = @{
            "Windows 7"            = 4
            "Windows 2008 R2"      = 5
            "Windows 2008 R2 Core" = 6
            "Windows 8"            = 7
            "Windows 2012"         = 8
            "Windows 2012 Core"    = 9
            "Windows 8.1"          = 10
            "Windows 2012 R2"      = 11
            "Windows 2012 R2 Core" = 12
            "Windows 10"           = 13
            "Windows 2016"         = 14
            "Windows 2016 Core"    = 15
            "Windows 2019"         = 15
            "Windows 2019 Core"    = 15
        }

        $tsType = @{
            RunCommandLine            = "Run Command Line"
            RestartComputer           = "Restart Computer"
            InstallApplication        = "Install Application"
            SetTaskSequenceVariable   = "Set Task Sequence Variable"
            InstallRolesAndFeatures   = "Install Roles and Features"
            UninstallRolesAndFeatures = "Uninstall Roles and Features"
        }

        # Create new step
        switch ($this.Type) {
            $tsType.RunCommandLine {
                $this.RunCommandLine($ts, $parentGroup)
            }
            $tsType.RestartComputer {
                $this.RestartComputer($ts, $parentGroup)
            }
            $tsType.InstallApplication {
                $this.AddApplication($ts, $parentGroup)
            }
            $tsType.SetTaskSequenceVariable {
                $this.SetTaskSequenceVariable($ts, $parentGroup)
            }
            $tsType.InstallRolesAndFeatures {
                $this.ValidateOsName($oSIndex)
                $this.InstallRolesAndFeatures($ts, $parentGroup, $oSIndex)
            }
            $tsType.UninstallRolesAndFeatures {
                $this.ValidateOsName($oSIndex)
                $this.UninstallRolesAndFeatures($ts, $parentGroup, $oSIndex)
            }
            default {
                throw "$($this.Type) is not a known Type. `nValid values: $($tsType.Values)"
            }
        }

        $ts.Save($this.TSPath)
    }

    [bool] Test() {
        $ts = $this.ReadTaskSequenceXML()

        $query = (Get-NodePathQuery -Path $this.Path -Name $this.Name)

        $step = $ts.SelectSingleNode($query)

        if (-not $step) {
            return $false
        }

        return $true
    }

    [cMDTTaskSequenceCustomize] Get() {
        return $this
    }

    [void] SetTaskSequenceFilePath() {
        If (-not $this.PSDrivePath) {
            throw "$($this.PSDrivePath) can't be null."
        }

        $this.TSPath = "$($this.PSDrivePath)\Control\$($this.TSFile)"
    }

    [xml] ReadTaskSequenceXML() {
        $this.SetTaskSequenceFilePath()

        $xml = [xml](Get-Content -Path $this.TSPath)

        if (-not $xml) {
            throw "$($this.TSPath) can't be found."
        }

        return $xml
    }

    [void] AddStepToTaskSequence($step, $parentGroup) {
        if ($this.InsertAfterStep) {
            $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")

            $parentGroup.InsertAfter($step, $insertAfterNode)
        }
        else {
            $parentGroup.AppendChild($step)
        }
    }

    [void] ValidateOsName($oSIndex) {
        if (-not ($oSIndex.$($this.OSName))) {
            throw "$($this.OSName) is not a known OS name! `nValid values: $($oSIndex.Keys)"
        }
    }

    [void] RunCommandLine($ts, $parentGroup) {

        $step = $ts.CreateElement("step")

        $step.SetAttribute("name", $this.Name)

        $step.SetAttribute("disable", "false")
        $step.SetAttribute("continueOnError", "false")
        $step.SetAttribute("successCodeList", $this.SuccessCodeList)
        $step.SetAttribute("description", $this.Description)
        $step.SetAttribute("startIn", $this.StartIn)

        $action = $ts.CreateElement("action")
        $action.AppendChild($ts.CreateTextNode("$($this.Command)"))

        $varList = $ts.CreateElement("defaultVarList")

        $var1 = $ts.CreateElement("variable")
        $var1.SetAttribute("name", "RunAsUser")
        $var1.SetAttribute("property", "RunAsUser")
        $var1.AppendChild($ts.CreateTextNode("$($this.RunAsUser)"))

        $var2 = $ts.CreateElement("variable")
        $var2.SetAttribute("name", "SMSTSRunCommandLineUserName")
        $var2.SetAttribute("property", "SMSTSRunCommandLineUserName")
        $var2.AppendChild($ts.CreateTextNode("$($this.CommandLineUserName)"))

        $var3 = $ts.CreateElement("variable")
        $var3.SetAttribute("name", "SMSTSRunCommandLineUserPassword")
        $var3.SetAttribute("property", "SMSTSRunCommandLineUserPassword")
        $var3.AppendChild($ts.CreateTextNode("$($this.CommandLineUserPassword)"))

        $var4 = $ts.CreateElement("variable")
        $var4.SetAttribute("name", "LoadProfile")
        $var4.SetAttribute("property", "LoadProfile")
        $var4.AppendChild($ts.CreateTextNode("$($this.LoadProfile)"))

        $varList.AppendChild($var1)
        $varList.AppendChild($var2)
        $varList.AppendChild($var3)
        $varList.AppendChild($var4)

        $step.AppendChild($action)
        $step.AppendChild($varList)

        $this.AddStepToTaskSequence($step, $parentGroup)
    }

    [void] RestartComputer($ts, $parentGroup) {

        $step = $ts.CreateElement("step")

        $step.SetAttribute("name", $this.Name)
        $step.SetAttribute("description", $this.Description)

        $step.SetAttribute("type", "SMS_TaskSequence_RebootAction")
        $step.SetAttribute("disable", "false")
        $step.SetAttribute("continueOnError", "false")
        $step.SetAttribute("successCodeList", $this.SuccessCodeList)
        $step.SetAttribute("runIn", "WinPEandFullOS")

        $action = $ts.CreateElement("action")
        $action.AppendChild($ts.CreateTextNode("smsboot.exe /target:WinPE"))

        $varList = $ts.CreateElement("defaultVarList")

        $var1 = $ts.CreateElement("variable")
        $var1.SetAttribute("name", "SMSRebootMessage")
        $var1.SetAttribute("property", "Message")

        $var2 = $ts.CreateElement("variable")
        $var2.SetAttribute("name", "SMSRebootTimeout")
        $var2.SetAttribute("property", "MessageTimeout")
        $var2.AppendChild($ts.CreateTextNode("60"))

        $var3 = $ts.CreateElement("variable")
        $var3.SetAttribute("name", "SMSRebootTarget")
        $var3.SetAttribute("property", "Target")

        $varList.AppendChild($var1)
        $varList.AppendChild($var2)
        $varList.AppendChild($var3)

        $step.AppendChild($action)
        $step.AppendChild($varList)

        $this.AddStepToTaskSequence($step, $parentGroup)
    }

    [void] AddApplication($ts, $parentGroup) {

        if (-not ($this.PSDriveName -or $this.PSDrivePath)) {
            throw "PSDriveName and/or PSDrivePath can't be null."
        }

        Import-MicrosoftDeploymentToolkitModule

        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        $app = Get-ChildItem -Path "$($this.PSDriveName):\Applications" -Recurse | Where-Object { $_.Name -eq $this.Name -and (-not $_.PSIsContainer) }

        if (-not $app) {
            throw "Application: $($this.Name) can't be found."
        }

        Write-Verbose -Message "Application GUID: $($app.guid)"

        $step = $ts.CreateElement("step")

        $step.SetAttribute("name", $this.Name)
        $step.SetAttribute("description", $this.Description)

        $step.SetAttribute("type", "BDD_InstallApplication")
        $step.SetAttribute("disable", "false")
        $step.SetAttribute("continueOnError", "false")
        $step.SetAttribute("successCodeList", $this.SuccessCodeList)
        $step.SetAttribute("runIn", "WinPEandFullOS")

        $action = $ts.CreateElement("action")
        $action.AppendChild($ts.CreateTextNode('cscript.exe "%SCRIPTROOT%\ZTIApplications.wsf"'))

        $varList = $ts.CreateElement("defaultVarList")

        $var1 = $ts.CreateElement("variable")
        $var1.SetAttribute("name", "ApplicationGUID")
        $var1.SetAttribute("property", "ApplicationGUID")
        $var1.AppendChild($ts.CreateTextNode($app.guid))

        $var2 = $ts.CreateElement("variable")
        $var2.SetAttribute("name", "ApplicationSuccessCodes")
        $var2.SetAttribute("property", "ApplicationSuccessCodes")
        $var2.AppendChild($ts.CreateTextNode("0 3010"))

        $varList.AppendChild($var1)
        $varList.AppendChild($var2)

        $step.AppendChild($action)
        $step.AppendChild($varList)

        $this.AddStepToTaskSequence($step, $parentGroup)
    }

    [void] SetTaskSequenceVariable($ts, $parentGroup) {

        if (-not ($this.TSVariableName -or $this.TSVariableValue)) {
            throw "TaskSequenceVariableName and/or TaskSequenceVariableValue can't be null."
        }

        $step = $ts.CreateElement("step")

        $step.SetAttribute("name", $this.Name)
        $step.SetAttribute("description", $this.Description)

        $step.SetAttribute("type", "SMS_TaskSequence_SetVariableAction")
        $step.SetAttribute("disable", "false")
        $step.SetAttribute("continueOnError", "false")
        $step.SetAttribute("successCodeList", $this.SuccessCodeList)

        $action = $ts.CreateElement("action")
        $action.AppendChild($ts.CreateTextNode('cscript.exe "%SCRIPTROOT%\ZTISetVariable.wsf"'))

        $varList = $ts.CreateElement("defaultVarList")

        $var1 = $ts.CreateElement("variable")
        $var1.SetAttribute("name", "VariableName")
        $var1.SetAttribute("property", "VariableName")
        $var1.AppendChild($ts.CreateTextNode($this.TSVariableName))

        $var2 = $ts.CreateElement("variable")
        $var2.SetAttribute("name", "VariableValue")
        $var2.SetAttribute("property", "VariableValue")
        $var2.AppendChild($ts.CreateTextNode($this.TSVariableValue))

        $varList.AppendChild($var1)
        $varList.AppendChild($var2)

        $step.AppendChild($action)
        $step.AppendChild($varList)

        $this.AddStepToTaskSequence($step, $parentGroup)
    }

    [void] InstallRolesAndFeatures($ts, $parentGroup, $oSIndex) {
        $step = $ts.CreateElement("step")

        $step.SetAttribute("name", $this.Name)
        $step.SetAttribute("description", $this.Description)

        $step.SetAttribute("type", "BDD_InstallRoles")
        $step.SetAttribute("disable", "false")
        $step.SetAttribute("continueOnError", "false")
        $step.SetAttribute("successCodeList", $this.SuccessCodeList)

        $step.SetAttribute("runIn", "WinPEandFullOS")

        $varList = $ts.CreateElement("defaultVarList")

        $index = $ts.CreateElement("variable")
        $index.SetAttribute("name", "OSRoleIndex")
        $index.SetAttribute("property", "OSRoleIndex")
        $index.AppendChild($ts.CreateTextNode($oSIndex.$($this.OSName)))
        $varList.AppendChild($index)

        $roles = $ts.CreateElement("variable")
        $roles.SetAttribute("name", "OSRoles")
        $roles.SetAttribute("property", "OSRoles")
        $roles.AppendChild($ts.CreateTextNode($this.OSRoles))
        $varList.AppendChild($roles)

        $services = $ts.CreateElement("variable")
        $services.SetAttribute("name", "OSRoleServices")
        $services.SetAttribute("property", "OSRoleServices")
        $services.AppendChild($ts.CreateTextNode($this.OSRoleServices))
        $varList.AppendChild($services)

        $features = $ts.CreateElement("variable")
        $features.SetAttribute("name", "OSFeatures")
        $features.SetAttribute("property", "OSFeatures")
        $features.AppendChild($ts.CreateTextNode($this.OSFeatures))
        $varList.AppendChild($features)

        $action = $ts.CreateElement("action")
        $action.AppendChild($ts.CreateTextNode('cscript.exe "%SCRIPTROOT%\ZTIOSRole.wsf"'))

        $step.AppendChild($varList)
        $step.AppendChild($action)

        $this.AddStepToTaskSequence($step, $parentGroup)
    }

    [void] UninstallRolesAndFeatures($ts, $parentGroup, $oSIndex) {
        $step = $ts.CreateElement("step")

        $step.SetAttribute("name", $this.Name)
        $step.SetAttribute("description", $this.Description)

        $step.SetAttribute("type", "BDD_UninstallRoles")
        $step.SetAttribute("disable", "false")
        $step.SetAttribute("continueOnError", "false")
        $step.SetAttribute("successCodeList", $this.SuccessCodeList)

        $step.SetAttribute("runIn", "WinPEandFullOS")

        $varList = $ts.CreateElement("defaultVarList")

        $index = $ts.CreateElement("variable")
        $index.SetAttribute("name", "OSRoleIndex")
        $index.SetAttribute("property", "OSRoleIndex")
        $index.AppendChild($ts.CreateTextNode($oSIndex.$($this.OSName)))
        $varList.AppendChild($index)

        $remove = $ts.CreateElement("variable")
        $remove.SetAttribute("name", "CompletelyRemove")
        $remove.SetAttribute("property", "CompletelyRemove")
        $remove.AppendChild($ts.CreateTextNode('false'))
        $varList.AppendChild($remove)

        $roles = $ts.CreateElement("variable")
        $roles.SetAttribute("name", "UninstallOSRoles")
        $roles.SetAttribute("property", "UninstallOSRoles")
        $roles.AppendChild($ts.CreateTextNode($this.OSRoles))
        $varList.AppendChild($roles)

        $services = $ts.CreateElement("variable")
        $services.SetAttribute("name", "UninstallOSRoleServices")
        $services.SetAttribute("property", "UninstallOSRoleServices")
        $services.AppendChild($ts.CreateTextNode($this.OSRoleServices))
        $varList.AppendChild($services)

        $features = $ts.CreateElement("variable")
        $features.SetAttribute("name", "UninstallOSFeatures")
        $features.SetAttribute("property", "UninstallOSFeatures")
        $features.AppendChild($ts.CreateTextNode($this.OSFeatures))
        $varList.AppendChild($features)

        $action = $ts.CreateElement("action")
        $action.AppendChild($ts.CreateTextNode('cscript.exe "%SCRIPTROOT%\ZTIOSRole.wsf" /uninstall'))

        $step.AppendChild($varList)
        $step.AppendChild($action)

        $this.AddStepToTaskSequence($step, $parentGroup)
    }
}
