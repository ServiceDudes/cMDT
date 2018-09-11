enum Ensure {
    Absent
    Present
}

[DscResource()]
class cMDTApplicationNoSource {

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty()]
    [string]$Enable = "True"

    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Key)]
    [string]$ShortName

    [DscProperty(Mandatory)]
    [string]$Version

    [DscProperty()]
    [string]$Comments
    
    [DscProperty()]
    [string]$Publisher

    [DscProperty()]
    [string]$Language
    
    [DscProperty(Mandatory)]
    [string]$CommandLine
    
    [DscProperty()]
    [string]$WorkingDirectory
    
    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [DscProperty()]
    [bool]$Debug

    [void] Set() {

        # Determine if application should be present or not
        if ($this.Ensure -eq [Ensure]::Present) {

            $this.ImportApplicationNoSource()
        }
        else {
            # Remove existing application
            If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.Path)\$($this.Name)' -Recurse -Levels 3 -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTApplication" -Type SET }

            # Remove application and traverse folder path where empty
            Invoke-RemovePath -Path "$($this.Path)\$($this.Name)" -Recurse -Levels 3 -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
        }
    }

    [bool] Test() {

        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false
        
        $present = Test-Path -Path "$($this.PSDriveName):\$($this.Path)\$($this.Name)"

        if ($present) {
            $app = Get-ChildItem -Path "$($this.PSDriveName):\Applications" -Recurse | Where-Object { $_.Name -eq $this.Name -and $_.Version -eq $this.Version }
            if ($app) {
                return $true
            }
        }

        return $false
    }

    [cMDTApplicationNoSource] Get() {
        return $this
    }

    [void] ImportApplicationNoSource() {

        If ($this.Debug) { Invoke-Logger -Message "Import-MicrosoftDeploymentToolkitModule" -Severity D -Category "cMDTApplication" -Type FUNCTION }

        # Import the required module MicrosoftDeploymentToolkitModule
        Import-MicrosoftDeploymentToolkitModule

        If ($this.Debug) { Invoke-Logger -Message "New-PSDrive -Name $($this.PSDriveName) -PSProvider 'MDTProvider' -Root $($this.PSDrivePath) -Verbose:$($false)" -Severity D -Category "cMDTApplication" -Type FUNCTION }

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        If ($this.Debug) { Invoke-Logger -Message "If (-not(Invoke-TestPath -Path $($this.Path) -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)))" -Severity D -Category "cMDTApplication" -Type FUNCTION }

        # Verify that the path for the application import exist
        If (-not(Invoke-TestPath -Path "$($this.PSDriveName):\$($this.Path)")) {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path $($this.Path) -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTApplication" -Type FUNCTION }

            # Create folder path to prepare for application import
            Invoke-CreatePath -Path "$($this.PSDriveName):\$($this.Path)" -Verbose
        }

        If ($this.Debug) { Invoke-Logger -Message "Import-MDTApplication -Path $($this.Path) -Enable $($this.Enabled) -Name $($this.Name) -ShortName $($this.ShortName) -Version $($this.Version) -Publisher $($this.Publisher) -Language $($this.Language) -CommandLine $($this.CommandLine) -WorkingDirectory $($this.WorkingDirectory) -Verbose" -Severity D -Category "cMDTApplication" -Type FUNCTION }   

        # Initialize application import to MDT
        Import-MDTApplication -Path "$($this.PSDriveName):$($this.Path)" -Enable $this.Enabled -Name $this.Name -ShortName $this.ShortName -Version $this.Version -Comments $this.Comments `
            -Publisher $this.Publisher -Language $this.Language -CommandLine $this.CommandLine -WorkingDirectory $this.WorkingDirectory -NoSource -Verbose
    }
}
