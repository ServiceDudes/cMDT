[DscResource()]
class cMDTTaskSequenceModifyStep {

    [DscProperty(Key)]
    [string]$TSFile

    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Mandatory)]
    [string]$Path

    [DscProperty()]
    [string]$Disable

    [DscProperty()]
    [string]$ContinueOnError

    [DscProperty()]
    [string]$SuccessCodeList
    
    [DscProperty()]
    [string]$Description

    [DscProperty()]
    [string]$StartIn

    [void] Set() {
        $this.ModifyTaskSequenceStep()
    }

    [bool] Test() {
        $ts = $this.ReadTaskSequenceXML()

        $query = (Get-NodePathQuery -Path $this.Path -Name $this.Name)

        $step = $ts.SelectSingleNode($query)

        if (-not $step) {
            return $false
        }

        $result = $this.VerifyingProperties($step)

        return $result
    }

    [cMDTTaskSequenceModifyStep] Get() {
        return $this
    }

    [void] ModifyTaskSequenceStep() {

        $ts = $this.ReadTaskSequenceXML()

        if (-not $ts) {
            throw "$($this.TSFile) can't be found."
        }
        
        $query = (Get-NodePathQuery -Path $this.Path -Name $this.Name)

        $step = $ts.SelectSingleNode($query)

        if (-not $step) { 
            throw "TaskSequenceModifyStep: $($this.Name) can't be found."
        }

        if ($this.ContinueOnError) { 
            $step.SetAttribute("continueOnError", $this.ContinueOnError.ToLower()) 
        }

        if ($this.Description) { 
            $step.SetAttribute("description", $this.Description) 
        }

        if ($this.Disable) { 
            $step.SetAttribute("disable", $this.Disable.ToLower()) 
        }

        if ($this.Name) { 
            $step.SetAttribute("name", $this.Name) 
        }

        if ($this.StartIn) { 
            $step.SetAttribute("startIn", $this.StartIn) 
        }

        if ($this.SuccessCodeList) { 
            $step.SetAttribute("successCodeList", $this.SuccessCodeList) 
        }
    
        $ts.Save($this.TSFile)
    }

    [bool] VerifyingProperties($step) {

        Write-Verbose -Message "$($step.InnerXml)"

        if ($this.ContinueOnError -and ($this.ContinueOnError.ToLower() -ne $step.continueOnError)) { 
            return $false
        }

        if ($this.Description -and ($this.Description -ne $step.description)) { 
            return $false
        }

        if ($this.Disable -and ($this.Disable.ToLower() -ne $step.disable)) { 
            return $false
        }

        if ($this.Name -and ($this.Name -ne $step.name)) { 
            return $false
        }

        if ($this.StartIn -and ($this.StartIn -ne $step.startIn)) { 
            return $false
        }

        if ($this.SuccessCodeList -and ($this.SuccessCodeList -ne $step.successCodeList)) { 
            return $false
        }

        return $true
    }
    
    [xml] ReadTaskSequenceXML() {
        $xml = [xml](Get-Content -Path "$($this.TSFile)")

        if (-not $xml) {
            throw "$($this.TSFile) can't be found."
        }

        return $xml
    }
}