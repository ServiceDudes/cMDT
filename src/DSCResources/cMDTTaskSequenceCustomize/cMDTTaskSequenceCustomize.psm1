[DscResource()]
class cMDTTaskSequenceCustomize {

    [DscProperty(Key)]
    [string]$TSFile

    [DscProperty(Mandatory)]
    [parameter(Mandatory = $true)]
    [ValidateSet("Run Command Line", "Restart Computer", "Install Application", "Set Task Sequence Variable")]
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

    [void] Set() {
        $ts = $this.ReadTaskSequenceXML()

        if (-not $ts) {
            throw "$($this.TSFile) can't be found."
        }

        $query = (Get-NodePathQuery -Path $this.Path)

        $parentGroup = $ts.SelectSingleNode($query)

        # Create new step
        switch ($this.Type) {
            "Run Command Line" {
                $this.RunCommandLine($ts, $parentGroup)
            }
            "Restart Computer" {
                $this.RestartComputer($ts, $parentGroup)
            }
            "Install Application" {
                $this.AddApplication($ts, $parentGroup)
            }
            "Set Task Sequence Variable" {
                $this.SetTaskSequenceVariable($ts, $parentGroup)
            }
        }

        $ts.Save($this.TSFile)
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

    [xml] ReadTaskSequenceXML() {
        $xml = [xml](Get-Content -Path "$($this.TSFile)")

        if (-not $xml) {
            throw "$($this.TSFile) can't be found."
        }

        return $xml
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

        if($this.InsertAfterStep) {
            $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")

            $parentGroup.InsertAfter($step,$insertAfterNode)
        } else {
            $parentGroup.AppendChild($step)
        }
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

        if($this.InsertAfterStep) {
            $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")

            $parentGroup.InsertAfter($step,$insertAfterNode)
        } else {
            $parentGroup.AppendChild($step)
        }
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

        if($this.InsertAfterStep) {
            $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")

            $parentGroup.InsertAfter($step,$insertAfterNode)
        } else {
            $parentGroup.AppendChild($step)
        }
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

        if($this.InsertAfterStep) {
            $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")

            $parentGroup.InsertAfter($step,$insertAfterNode)
        } else {
            $parentGroup.AppendChild($step)
        }
    }
}