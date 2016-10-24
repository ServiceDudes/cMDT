enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTApplicationBundle
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [string]$BundleName

    [DscProperty(Mandatory)]
    [string[]]$BundledApplications

    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [DscProperty()]
    [string]$Version = [string]::Empty
    
    [DscProperty()]
    [string]$Publisher = [string]::Empty

    [DscProperty()]
    [string]$Language = [string]::Empty

    [DscProperty()]
    [string]$Hide = $false

    [DscProperty()]
    [string]$Enable = $true

    [DscProperty()]
    [string]$Folder = 'Applications'

    [void] Set()
    {    
        
        # Call function to check if bundle exist
        $present           = $this.ApplicationBundleExists()

        # Call function to check if bundle needs to be updated
        $bundleNeedsUpdate = $this.ApplicationBundleNeedsUpdate()
        
        # Determine if bundle should be present or not
        if ($this.Ensure -eq [ensure]::Present -and $present -eq $false)
        {
            if ($bundleNeedsUpdate)
            {

                # Update bundle
                $this.UpdateApplicationBundle()
            }
            else
            {

                # Create bundle
                $this.CreateApplicationBundle()
            }
        }
        elseif ($this.Ensure -eq [ensure]::Absent -and $present -eq $true)
        {
            
            # Remove bundle
            $this.RemoveApplicationBundle()
        }
        
    }

    [bool] Test()
    {
        
        # Call function to check if bundle exist
        $present = $this.ApplicationBundleExists()

        # Return boolean from test method
        if ($this.Ensure -eq [ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTApplicationBundle] Get()
    {
        return $this
    }

    [bool] ApplicationBundleExists()
    {

        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false
        
        # Check if bundle exist
        $bundle = Get-ChildItem "$($this.PSDriveName):" -Recurse | 
                    Where-Object {$_.Name -eq "$($this.BundleName)" -and $_.NodeType -eq 'Application'}

        if ($bundle)
        {

            # Check if bundle needs to be updated
            if ($this.ApplicationBundleNeedsUpdate())
            {
                return $false
            }
            return $true
        }
        return $false

    }

    [bool] ApplicationBundleNeedsUpdate()
    {

        # Import MicrosoftDeploymentToolkitModule
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false
    
        # Check if bundle exist
        $bundle = Get-ChildItem "$($this.PSDriveName):" -Recurse | 
                    Where-Object {$_.Name -eq "$($this.BundleName)" -and $_.NodeType -eq 'Application'}

        if (!$bundle)
        {
            return $false
        }

        # Get GUID:s from bundle
        $applicationGuids = $this.GetApplicationGuids()

        # Compare GUID:s to check if update is needed
        #BAD Implement: if ((Compare-Object $applicationGuids $bundle.Dependency) -ne $null) {return $true}        
        if ($null -ne (Compare-Object $applicationGuids $bundle.Dependency)) {return $true}

        # Verify bundle parameter properties
        if ($bundle.ShortName -ne $this.BundleName)            {return $true}
        if ($bundle.Version   -ne $this.Version)               {return $true}
        if ($bundle.Publisher -ne $this.Publisher)             {return $true}
        if ($bundle.Language  -ne $this.Language)              {return $true}
        if ($bundle.Hide      -ne $this.Hide.ToString())       {return $true}
        if ($bundle.Enable    -ne $this.Enable.ToString())     {return $true}
            
        return $false        
    }

    [void] CreateApplicationBundle()
    {

        # Import MicrosoftDeploymentToolkitModule
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        # Set splatting parameters from input
        $importParams = @{
            Path        = "$($this.PSDriveName):\$($this.Folder)"
            Enable      = $this.Enable.ToString()
            Hide        = $this.Hide.ToString()
            Name        = $this.BundleName
            ShortName   = $this.BundleName
            DisplayName = $this.BundleName
            Version     = $this.Version
            Publisher   = $this.Publisher
            Language    = $this.Language
            Bundle      = $true
        }

        # Import MDT application
        Import-MDTApplication @importParams > $null

        # Define path to bundle in MDT
        $path = "$($this.PSDriveName):\$($this.Folder)\$($this.BundleName)"
        
        # Get GUID:s for bundle
        $applicationGuids = $this.GetApplicationGuids()

        # Set GUID:s to property for matching capabilities
        Set-ItemProperty -Path $path -Name Dependency -Value $applicationGuids

    }

    [void] UpdateApplicationBundle()
    {

        # Import MicrosoftDeploymentToolkitModule
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false
        
        # Define path to bundle in MDT
        $path = "$($this.PSDriveName):\$($this.Folder)\$($this.BundleName)"

        # Define attributes to be verified
        $properties = @('Enable',
                        'Hide',
                        'ShortName',
                        'DisplayName',
                        'Version',
                        'Publisher',
                        'Language')
        
        # Loop through attributes and update accordingly
        foreach ($property in $properties)
        {
            if ($property -eq 'ShortName' -or $property -eq 'DisplayName')
            {
                Set-ItemProperty -Path "$path" -Name "$property" -Value "$($this.BundleName)"
            }
            else
            {
                Set-ItemProperty -Path "$path" -Name "$property" -Value "$($this.$property.ToString())"
            }
        }
        
        # Get GUID:s for bundle
        $applicationGuids = $this.GetApplicationGuids()

        # Set GUID:s to property for matching capabilities
        Set-ItemProperty -Path $path -Name Dependency -Value $applicationGuids
    }

    [void] RemoveApplicationBundle()
    {
        Import-MicrosoftDeploymentToolkitModule
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false
        $path = "$($this.PSDriveName):\$($this.Folder)\$($this.BundleName)"
        Remove-Item -Path $path
    }
    [string[]] GetApplicationGuids()
    {
        Import-MicrosoftDeploymentToolkitModule
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false
        
        [string[]]$applicationGuids = @()
        foreach ($application in $this.BundledApplications)
        {
            $applicationGuid = Get-ChildItem "$($this.PSDriveName):" -Recurse | 
                        Where-Object {$_.Name -eq $application -and $_.NodeType -eq 'Application'} | 
                        Select-Object -ExpandProperty guid
            if ($applicationGuid)
            {
                $applicationguids += $applicationGuid
            }
        }
        return $applicationGuids
    }
    
}
