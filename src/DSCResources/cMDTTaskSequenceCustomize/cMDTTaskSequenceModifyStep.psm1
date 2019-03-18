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

    [DscProperty()]
    [string]$PSDrivePath

    [DscProperty()]
    [string]$TSPath

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
            throw "$($this.TSPath) can't be found."
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

        $ts.Save($this.TSPath)
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
}
