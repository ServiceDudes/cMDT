enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDT_TS_Step_SetVariable
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [string]$TaskSequenceParentGroupName

    [DscProperty(Key)]
    [string]$TaskSequenceVariableName

    [DscProperty(Key)]
    [string]$TaskSequenceVariableValue
    
    [DscProperty(Key)]
    [string]$TaskSequenceStepName

    [DscProperty()]
    [string]$TaskSequenceStepDescription

    [DscProperty()]
    [bool]$Disable

    [DscProperty()]
    [bool]$ContinueOnError

    [DscProperty()]
    [string]$SuccessCodeList

    [DscProperty(Key)]
    [string]$TaskSequenceId

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [DscProperty(Mandatory)]
    [string]$InsertAfterStep

    [void] Set()
    {    
        [xml]$xml = $this.ReadTaskSequenceXML()
        
        $present         = $this.TaskSequenceStepExists()
        $stepNeedsUpdate = $this.TaskSequenceStepNeedsUpdate()
        
        if ($this.Ensure -eq [ensure]::Present -and $present -eq $false)
        {
            if ($stepNeedsUpdate)
            {
                $this.UpdateTaskSequenceStep($xml)
            }
            else
            {
                $this.CreateTaskSequenceStep($xml)
            }
        }
        elseif ($this.Ensure -eq [ensure]::Absent -and $present -eq $true)
        {
            $this.RemoveTaskSequenceStep($xml)
        }
        
    }

    [bool] Test()
    {
        
        $present = $this.TaskSequenceStepExists()

        if ($this.Ensure -eq [ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDT_TS_Step_SetVariable] Get()
    {
        return $this
    }

    [bool] TaskSequenceStepExists()
    {
        [xml]$xml = $this.ReadTaskSequenceXML()
        
        #Select parent group by name
        $parentGroup = $xml.SelectSingleNode("sequence/group[@name='$($this.TaskSequenceParentGroupName)']")
        #Select parent node by name
        $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")

        #Next sibling should be the same name as the task sequence step name if it exists.
        if ($insertAfterNode.NextSibling.name -eq $($this.TaskSequenceStepName))
        {
            if ($this.TaskSequenceStepNeedsUpdate())
            {
                return $false
            }   
            return $true
        }
        return $false
    }

    [bool] TaskSequenceStepNeedsUpdate()
    {        
        [xml]$xml        = $this.ReadTaskSequenceXML()
        $parentGroup     = $xml.SelectSingleNode("sequence/group[@name='$($this.TaskSequenceParentGroupName)']")
        $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")
        
        if ($insertAfterNode.NextSibling.name -ne $($this.TaskSequenceStepName))
        {
            return $false
        }

        $node      = $insertAfterNode.NextSibling
        $varName   = $node.defaultVarList.SelectSingleNode("variable[@name='VariableName']").InnerText
        $varValue  = $node.defaultVarList.SelectSingleNode("variable[@name='VariableValue']").InnerText

        if ($varName              -ne $this.TaskSequenceVariableName)    {return $true}
        if ($varValue             -ne $this.TaskSequenceVariableValue)   {return $true}
        if ($node.description     -ne $this.TaskSequenceStepDescription) {return $true}
        if ($node.disable         -ne $this.Disable)                     {return $true}
        if ($node.continueOnError -ne $this.ContinueOnError)             {return $true}
        if ($node.successCodeList -ne $this.SuccessCodeList)             {return $true}
            
        return $false        
    }

    [void] CreateTaskSequenceStep($xml)
    {
        $parentGroup = $xml.SelectSingleNode("sequence/group[@name='$($this.TaskSequenceParentGroupName)']")
        $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")
    
        $stepNode = $xml.CreateElement("step")
        $stepNode.SetAttribute("type","SMS_TaskSequence_SetVariableAction")
        $stepNode.SetAttribute("name","$($this.TaskSequenceStepName)")
        $stepNode.SetAttribute("description","$($this.TaskSequenceStepDescription)")
        $stepNode.SetAttribute("disable","$($this.Disable.ToString().ToLower())")
        $stepNode.SetAttribute("continueOnError","$($this.ContinueOnError.ToString().ToLower())")
        $stepNode.SetAttribute("successCodeList","$($this.SuccessCodeList)")
            $defaultVarListNode = $xml.CreateElement("defaultVarList")
                $variableNode1 = $xml.CreateElement("variable")
                $variableNode1.SetAttribute("name","VariableName")
                $variableNode1.SetAttribute("property","VariableName")
                $variableNode1.InnerText = "$($this.TaskSequenceVariableName)"
                $defaultVarListNode.AppendChild($variableNode1) > $null

                $variableNode2 = $xml.CreateElement("variable")
                $variableNode2.SetAttribute("name","VariableValue")
                $variableNode2.SetAttribute("property","VariableValue")
                $variableNode2.InnerText = "$($this.TaskSequenceVariableValue)"
                $defaultVarListNode.AppendChild($variableNode2) > $null

            $stepNode.AppendChild($defaultVarListNode) > $null
            $actionNode = $xml.CreateElement("action")
            $actionNode.InnerText = "cscript.exe `"%SCRIPTROOT%\ZTISetVariable.wsf`""
        $stepNode.AppendChild($actionNode) > $null
    
        $parentGroup.InsertAfter($stepNode,$insertAfterNode)
        $this.SaveTaskSequenceXML($xml)
    }

    [void] UpdateTaskSequenceStep($xml)
    {
        $parentGroup     = $xml.SelectSingleNode("sequence/group[@name='$($this.TaskSequenceParentGroupName)']")
        $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")
        $node            = $insertAfterNode.NextSibling

        $node.SetAttribute("name","$($this.TaskSequenceStepName)")
        $node.SetAttribute("description","$($this.TaskSequenceStepDescription)")
        $node.SetAttribute("disable","$($this.Disable.ToString().ToLower())")
        $node.SetAttribute("continueOnError","$($this.ContinueOnError.ToString().ToLower())")
        $node.SetAttribute("successCodeList","$($this.SuccessCodeList)")

        $node.defaultVarList.SelectSingleNode("variable[@name='VariableName']").InnerText  = $this.TaskSequenceVariableName
        $node.defaultVarList.SelectSingleNode("variable[@name='VariableValue']").InnerText = $this.TaskSequenceVariableValue
        
        $this.SaveTaskSequenceXML($xml)
    }

    [void] RemoveTaskSequenceStep($xml)
    {
        $parentGroup = $xml.SelectSingleNode("sequence/group[@name='$($this.TaskSequenceParentGroupName)']")
        #Select parent node by name
        $insertAfterNode = $parentGroup.SelectSingleNode("step[@name='$($this.InsertAfterStep)']")

        #Next sibling should be the same name as the task sequence step name if it exists.
        if ($insertAfterNode.NextSibling.name -eq $($this.TaskSequenceStepName))
        {
            $node = $insertAfterNode.NextSibling
            $node.ParentNode.RemoveChild($node) > $null
            $this.SaveTaskSequenceXML($xml)
        }
    }
    
    [xml] ReadTaskSequenceXML()
    {
        return [xml](Get-Content -Path "$($this.PSDrivePath)\Control\$($this.TaskSequenceId)\ts.xml")
    }
    [void] SaveTaskSequenceXML($xml)
    {
        $xml.Save("$($this.PSDrivePath)\Control\$($this.TaskSequenceId)\ts.xml")
    }
}