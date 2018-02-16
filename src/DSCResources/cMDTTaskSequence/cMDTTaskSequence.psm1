enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTTaskSequence
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Key)]
    [string]$Name

    [DscProperty()]
    [string]$OperatingSystemPath

    [DscProperty()]
    [string]$WIMFileName

    [DscProperty(Mandatory)]
    [string]$ID

    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [void] Set()
    {

        # Determine present/absent
        if ($this.ensure -eq [Ensure]::Present)
        {

            # Call function to import task sequence
            $this.ImportTaskSequence()
        }
        else
        {

            # Remove path recursively
            Invoke-RemovePath -Path "$($this.path)\$($this.name)" -Recurse -Levels 3 -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
        }
    }

    [bool] Test()
    {

        # Test if path exist
        $present = Invoke-TestPath -Path "$($this.path)\$($this.name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath 
        
        # Return boolean from test method
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTTaskSequence] Get()
    {
        return $this
    }

    [void] ImportTaskSequence()
    {

        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        $OperatingSystemFile = $null

        If ($this.OperatingSystemPath)
        {

            # Get OS file name
            $OperatingSystemFile = $this.OperatingSystemPath
        }

        # Get existing OS file name
        If ($this.WIMFileName)
        {
            $Directory = $this.Name.Replace(" x64","")
            $Directory = $Directory.Replace(" x32","")

            $OperatingSystemFiles = (Get-ChildItem -Path "$($this.PSDriveName):\Operating Systems\$($this.Path.Split("\")[-1])")
            ForEach ($OSFile in $OperatingSystemFiles)
            {
                If ($OSFile.Name -like "*$($this.WIMFileName)*")
                {
                    $OperatingSystemFile = "$($this.PSDriveName):\Operating Systems\$($this.Path.Split("\")[-1])\$($OSFile.Name)"
                }
            }
        }

        If ($OperatingSystemFile)
        {

            # Create path for task sequence
            if(-not (Test-Path $this.Path)){
                Invoke-CreatePath -Path "$($this.PSDriveName):\Task Sequences\$($this.Path.Split("\")[-1])" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
            }

            # Import task sequence
            Import-MDTTaskSequence -path $this.Path -Name $this.Name -Template "Client.xml" -Comments "" -ID $this.ID -Version "1.0" -OperatingSystemPath $OperatingSystemFile -FullName "Windows User" -OrgName "Addlevel" -HomePage "about:blank" -Verbose
        }
    }
}
