enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTPersistentDrive
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Mandatory)]
    [string]$Description

    [DscProperty(Mandatory)]
    [string]$NetworkPath

    [void] Set()
    {

        # Determine present/absent
        if ($this.ensure -eq [Ensure]::Present)
        {
            
            # If present create drive
            $this.CreateDirectory()
        }
        else
        {

            # If absent remove drive
            $this.RemoveDirectory()
        }
    }

    [bool] Test()
    {

        # Check if persistent drive exist
        $present = $this.TestDirectoryPath()
        
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

    [cMDTPersistentDrive] Get()
    {
        return $this
    }

    [bool] TestDirectoryPath()
    {
        $present = $false

        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        # Check if persistent drive exist
        if (Test-Path -Path $this.Path -PathType Container -ErrorAction Ignore)
        {
            $mdtShares = (GET-MDTPersistentDrive -ErrorAction SilentlyContinue)
            If ($mdtShares)
            {
                ForEach ($share in $mdtShares)
                {
                    If ($share.Name -eq $this.Name)
                    {
                        $present = $true
                    }
                }
            } 
        }

        return $present
    }

    [void] CreateDirectory()
    {

        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.Name -PSProvider "MDTProvider" -Root $this.Path -Description $this.Description -NetworkPath $this.NetworkPath -Verbose:$false | `        # Create MDT persistent drive        Add-MDTPersistentDrive -Verbose

    }

    [void] RemoveDirectory()
    {
        
        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        Write-Verbose -Message "Removing MDTPersistentDrive $($this.Name)"

        # Create PSDrive
        New-PSDrive -Name $this.Name -PSProvider "MDTProvider" -Root $this.Path -Description $this.Description -NetworkPath $this.NetworkPath -Verbose:$false | `        # Remove MDT persistent drive        Remove-MDTPersistentDrive -Verbose
    }
}
