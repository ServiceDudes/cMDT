enum Ensure {
    Absent
    Present
}

[DscResource()]
class cMDTSettings {
    [DscProperty(Key)]
    [Ensure] $Ensure

    [DscProperty()]
    [string]$Description = "MDT Deployment Share"

    [DscProperty()]
    [string]$Comments

    [DscProperty()]
    [bool]$EnableMulticast

    [DscProperty()]
    [bool]$SupportX86

    [DscProperty()]
    [bool]$SupportX64

    [DscProperty()]
    [string]$UNCPath

    [DscProperty()]
    [string]$PhysicalPath
    
    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [void] Set() {
        Import-MicrosoftDeploymentToolkitModule

        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        $present = $this.VerifyMDTSettings()
        
        if ($this.Ensure -eq [ensure]::Present -and $present -eq $false) {
            $this.UpdateMDTSettings()
        }
        elseif ($this.Ensure -eq [ensure]::Absent) {
            $this.RestoreDefaultSettings()
        }
    }

    [bool] Test() {
        Import-MicrosoftDeploymentToolkitModule

        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        $present = $this.VerifyMDTSettings()
        return $present
    }

    [cMDTSettings] Get() {
        return $this
    }

    [void] UpdateMDTSettings() {

        # Define host and ports
        if ($this.Description) {
            Set-ItemProperty "$($this.PSDriveName):\" -Name Description -Value $this.Description
        }

        if ($this.Comments) {
            Set-ItemProperty "$($this.PSDriveName):\" -Name Comments -Value $this.Comments
        }
        
        if ($this.SupportX86) {
            Set-ItemProperty "$($this.PSDriveName):\" -Name SupportX86 -Value $this.SupportX86
        }
        
        if ($this.SupportX64) {
            Set-ItemProperty "$($this.PSDriveName):\" -Name SupportX64 -Value $this.SupportX64
        }

        if ($this.EnableMulticast) {
            Set-ItemProperty "$($this.PSDriveName):\" -Name EnableMulticast -Value $this.EnableMulticast
        }
    }

    [bool] VerifyMDTSettings() {

        if ($this.Description -and (Get-ItemProperty "$($this.PSDriveName):\" -Name Description).Description -ne $this.Description) {
            return $false
        }

        if ($this.Comments -and (Get-ItemProperty "$($this.PSDriveName):\" -Name Comments).Comments -ne $this.Comments) {
            return $false
        }

        if ($this.EnableMulticast -and (Get-ItemProperty "$($this.PSDriveName):\" -Name EnableMulticast).EnableMulticast -ne $this.EnableMulticast) {
            return $false
        }

        if ($this.SupportX86 -and (Get-ItemProperty "$($this.PSDriveName):\" -Name SupportX86).SupportX86 -ne $this.SupportX86) {
            return $false
        }

        if ($this.SupportX64 -and (Get-ItemProperty "$($this.PSDriveName):\" -Name SupportX64).SupportX64 -ne $this.SupportX64) {
            return $false
        }

        if ($this.UNCPath -and (Get-ItemProperty "$($this.PSDriveName):\" -Name UNCPath).UNCPath -ne $this.UNCPath) {
            return $false
        }

        if ($this.PhysicalPath -and (Get-ItemProperty "$($this.PSDriveName):\" -Name PhysicalPath).PhysicalPath -ne $this.PhysicalPath) {
            return $false
        }

        return $true
    }

    [void] RestoreDefaultSettings() {

        Set-ItemProperty "$($this.PSDriveName):\" -Name Description -Value "MDT Deployment Share"
        Set-ItemProperty "$($this.PSDriveName):\" -Name Comments -Value ""
        Set-ItemProperty "$($this.PSDriveName):\" -Name SupportX86 -Value $true
        Set-ItemProperty "$($this.PSDriveName):\" -Name SupportX64 -Value $true
        Set-ItemProperty "$($this.PSDriveName):\" -Name EnableMulticast -Value $false
    }
}
