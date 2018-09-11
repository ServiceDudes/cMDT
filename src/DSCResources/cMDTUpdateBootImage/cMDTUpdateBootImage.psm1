
[DscResource()]
class cMDTUpdateBootImage {
    [DscProperty(Key)]
    [string]$Version

    [DscProperty(Key)]
    [string]$PSDeploymentShare

    [DscProperty(Mandatory)]
    [bool]$Force

    [DscProperty(Mandatory)]
    [bool]$Compress

    [DscProperty(Mandatory)]
    [string]$DeploymentSharePath

    [DscProperty()]
    [string]$ExtraDirectory

    [DscProperty()]
    [string]$BackgroundFile

    [DscProperty()]
    [string]$LiteTouchWIMDescription

    [DscProperty()]
    [string]$FeaturePacks
    
    [DscProperty()]
    [bool]$GenerateLiteTouchISO = $false
      
    [void] Set() {
        $this.UpdateBootImage()
    }

    [bool] Test() {
        Return ($this.VerifyVersion())
    }

    [cMDTUpdateBootImage] Get() {
        return $this
    }

    [bool] VerifyVersion() {
        [bool]$match = $false

        if ((Get-Content -Path "$($this.DeploymentSharePath)\Boot\CurrentBootImage.version" -ErrorAction Ignore) -eq $this.Version) {
            $match = $true
        }
        
        return $match
    }

    [void] UpdateBootImage() {

        Import-MicrosoftDeploymentToolkitModule

        New-PSDrive -Name $this.PSDeploymentShare -PSProvider "MDTProvider" -Root $this.DeploymentSharePath -Verbose:$false

        If ([string]::IsNullOrEmpty($($this.ExtraDirectory))) {
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.ExtraDirectory -Value ""
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.ExtraDirectory -Value ""
        }
        ElseIf (Invoke-TestPath -Path "$($this.DeploymentSharePath)\$($this.ExtraDirectory)") {

            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.ExtraDirectory -Value "$($this.DeploymentSharePath)\$($this.ExtraDirectory)"                        
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.ExtraDirectory -Value "$($this.DeploymentSharePath)\$($this.ExtraDirectory)"                       
        }

        If ([string]::IsNullOrEmpty($($this.BackgroundFile))) {
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.BackgroundFile -Value ""
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.BackgroundFile -Value ""
        }

        ElseIf (Invoke-TestPath -Path "$($this.DeploymentSharePath)\$($this.BackgroundFile)") {
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.BackgroundFile -Value "$($this.DeploymentSharePath)\$($this.BackgroundFile)"
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.BackgroundFile -Value "$($this.DeploymentSharePath)\$($this.BackgroundFile)"
        }

        If ($this.LiteTouchWIMDescription) { Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.LiteTouchWIMDescription -Value "$($this.LiteTouchWIMDescription) x64 $($this.Version)" }
        Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.GenerateLiteTouchISO -Value $this.GenerateLiteTouchISO

        If ($this.LiteTouchWIMDescription) { Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.LiteTouchWIMDescription -Value "$($this.LiteTouchWIMDescription) x86 $($this.Version)" }
        Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.GenerateLiteTouchISO -Value $this.GenerateLiteTouchISO
        
        If ($this.GenerateLiteTouchISO -and $this.LiteTouchWIMDescription) {
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.LiteTouchISOName -Value "$($this.LiteTouchWIMDescription)_x64.iso".Replace(' ', '_')
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.LiteTouchISOName -Value "$($this.LiteTouchWIMDescription)_x86.iso".Replace(' ', '_')
        }
        
        If ([string]::IsNullOrEmpty($($this.FeaturePacks))) {
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.FeaturePacks -Value ""
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.FeaturePacks -Value ""
        }
        Else {
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x64.FeaturePacks -Value $($this.FeaturePacks)
            Set-ItemProperty "$($this.PSDeploymentShare):" -Name Boot.x86.FeaturePacks -Value $($this.FeaturePacks)
        }

        #The Update-MDTDeploymentShare command crashes WMI when run from inside DSC. This section is a work around.
        $aPSDeploymentShare = $this.PSDeploymentShare
        $aDeploymentSharePath = $this.DeploymentSharePath
        $aForce = $this.Force
        $aCompress = $this.Compress
        $jobArgs = @($aPSDeploymentShare, $aDeploymentSharePath, $aForce, $aCompress)

        $job = Start-Job -Name UpdateMDTDeploymentShare -Scriptblock {
            Import-Module "$env:ProgramFiles\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1" -ErrorAction Stop -Verbose:$false
            New-PSDrive -Name $args[0] -PSProvider "MDTProvider" -Root $args[1] -Verbose:$false
            Update-MDTDeploymentShare -Path "$($args[0]):" -Force:$args[2] -Compress:$args[3]
        } -ArgumentList $jobArgs

        $job | Wait-Job -Timeout 1800 
        $timedOutJobs = Get-Job -Name UpdateMDTDeploymentShare | Where-Object {$_.State -eq 'Running'} | Stop-Job -PassThru

        If ($timedOutJobs) {
            Write-Error "Update-MDTDeploymentShare job exceeded timeout limit of 900 seconds and was aborted"
        }
        Else {
            Set-Content -Path "$($this.DeploymentSharePath)\Boot\CurrentBootImage.version" -Value "$($this.Version)"
        }
    }
    
    
}
