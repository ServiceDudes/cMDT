enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTCustomize
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure
    
    [DscProperty(Mandatory)]
    [string]$Version

    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Key)]
    [string]$Path
    
    [DscProperty(Mandatory)]
    [string]$SourcePath

    [DscProperty(Mandatory)]
    [string]$TempLocation

    [bool]$Protected

    [DscProperty(NotConfigurable)]
    [string]$Directory

    [void] Set()
    {

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.SourcePath   

        # Set file name basen on name and version
        $filename = "$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator))_$($this.Version).zip"

        # Set folder name as file name without version
        $foldername = (Get-FileNameFromPath -Path $this.SourcePath -Separator $separator).Split(".")[0]

        # Determine if file path is an SMB or weblink and should be downloaded
        [bool]$download = $True
        If (($separator -eq "/") -Or ($this.SourcePath.Substring(0,2) -eq "\\"))
        { $targetdownload = "$($this.TempLocation)\$($filename)" }
        Else
        { $targetdownload = "$($this.SourcePath)_$($this.Version).zip" ; $download = $False }

        # Set extraction folder name
        $extractfolder = "$($this.path)\$($this.name)"

        # Set reference file name to enable versioning
        $referencefile = "$($this.Path)\$($this.name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version"

        # Determine if customization should be present or not
        if ($this.ensure -eq [Ensure]::Present)
        {
            
            # Check if customization already exist in MDT
            $present = Invoke-TestPath -Path "$($this.path)\$($this.name)"

            if ($present)
            {
                #  Upgrade existing customization

                # If customization must be downloaded before imported
                If ($download)
                {
                    # Start download of customization
                    Invoke-WebDownload -Source "$($this.SourcePath)_$($this.Version).zip" -Target $targetdownload -Verbose

                    # Test if download was successfull
                    $present = Invoke-TestPath -Path $targetdownload

                    # If download was not successfull
                    If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }
                }

                # Check if protected mode has been defined
                if (-not $this.Protected)
                {
                    # Check if reference file exist
                    $present = Invoke-TestPath -Path $referencefile

                    # If it exist remove the reference file
                    If ($present) { Invoke-RemovePath -Path $referencefile }
                }

                # Expand archive to folder in MDT
                Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder -Verbose

                # If downloaded, remove downloaded archive after expansion
                If ($download) { Invoke-RemovePath -Path $targetdownload }

                # If protected mode has been defined create a new reference file
                If ($this.Protected) { New-ReferenceFile -Path $referencefile }
            }
            else
            {

                #  Import new customization

                # If customization must be downloaded before imported
                If ($download)
                {
                    # Start download of customization
                    Invoke-WebDownload -Source "$($this.SourcePath)_$($this.Version).zip" -Target $targetdownload -Verbose

                    # Test if download was successfull
                    $present = Invoke-TestPath -Path $targetdownload

                    # If download was not successfull
                    If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }
                }

                # Expand archive to folder in MDT
                Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder -Verbose

                # If downloaded, remove downloaded archive after expansion
                If ($download) { Invoke-RemovePath -Path $targetdownload }

                # Create a new reference file
                New-ReferenceFile -Path $referencefile 
            }

            # Set versioning file content
            Set-Content -Path $referencefile -Value "$($this.Version)"
        }
        else
        {
            # Remove customization and traverse folder path where empty
            Invoke-RemovePath -Path "$($this.path)\$($this.name)" -Verbose
        }
    }

    [bool] Test()
    {

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.SourcePath

        # Check if customization exist in MDT
        $present = Invoke-TestPath -Path "$($this.path)\$($this.name)"

        # If customization exists and should be present
        if (($present) -and ($this.ensure -eq [Ensure]::Present))
        {
            # Verify existence of reference file
            If (Test-Path -Path "$($this.Path)\$($this.name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version" -ErrorAction Ignore)
            {
                # Verify customization version against the reference file
                $match = Compare-Version -Source "$($this.Path)\$($this.name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version" -Target $this.Version

                # If versioning file content do not match
                if (-not ($match))
                {

                    Write-Verbose "$($this.Name) version has been updated on the pull server"
                    $present = $false
                }
            }
            else
            {
                $present = $false
            }
        }

        # If customization exist, should be absent but defined as protected
        if (($present) -and ($this.Protected) -and ($this.ensure -eq [Ensure]::Absent))
        {            Write-Verbose "Folder protection override mode defined"            Write-Verbose "$($this.Name) folder will not be removed"            return $true
        }
        
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

    [cMDTCustomize] Get()
    {
        return $this
    }
}
