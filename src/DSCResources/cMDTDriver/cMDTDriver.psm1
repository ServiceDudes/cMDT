enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTDriver
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
    [string]$Enabled
    
    [DscProperty(Mandatory)]
    [string]$Comment
    
    [DscProperty(Mandatory)]
    [string]$SourcePath

    [DscProperty(Mandatory)]
    [string]$TempLocation

    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [DscProperty()]
    [bool]$Debug

    [void] Set()
    {

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.SourcePath

        # Set file name based on name, version and type
        $filename = "$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator))_$($this.Version).zip"

        If ($this.Debug) { Invoke-Logger -Message "Download file: $filename" -Severity D -Category "cMDTDriver" -Type SET }

        # Set folder name as file name without version
        $foldername = (Get-FileNameFromPath -Path $this.SourcePath -Separator $separator).Split(".")[0]

        If ($this.Debug) { Invoke-Logger -Message "Folder name: $foldername" -Severity D -Category "cMDTDriver" -Type SET }

        # Determine if file path is an SMB or weblink and should be downloaded
        [bool]$download = $True
        If (($separator -eq "/") -Or ($this.SourcePath.Substring(0,2) -eq "\\"))
        { $targetdownload = "$($this.TempLocation)\$($filename)" }
        Else
        { $targetdownload = "$($this.SourcePath)_$($this.Version).zip" ; $download = $False }
        If ($this.Debug) { Invoke-Logger -Message "Target download: $targetdownload" -Severity D -Category "cMDTDriver" -Type SET }

        # Set temporary extraction folder name
        $extractfolder = "$($this.TempLocation)\$($foldername)"

        If ($this.Debug) { Invoke-Logger -Message "Extract folder: $extractfolder" -Severity D -Category "cMDTDriver" -Type SET }

        # Set reference file name to enable versioning
        $referencefile = "$($this.PSDrivePath)\Out-of-Box Drivers\$($($this.Path.Split("\")[-2]).Replace(' ',''))$($($this.Path.Split("\")[-1]).Replace(' ',''))$($($this.Name).Replace(' ',''))$($this.SourcePath.Split($separator)[-1]).version"

        If ($this.Debug) { Invoke-Logger -Message "Reference file: $referencefile" -Severity D -Category "cMDTDriver" -Type SET }

        # Determine if driver should be present or not
        if ($this.ensure -eq [Ensure]::Present)
        {
            
            If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.path)\$($this.name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)" -Severity D -Category "cMDTDriver" -Type SET }

            # Check if driver already exist in MDT
            $present = Invoke-TestPath -Path "$($this.path)\$($this.name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath

            If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDriver" -Type SET }

            if ($present)
            {
                #  Upgrade existing driver

                If ($this.Debug) { Invoke-Logger -Message "Download: $download" -Severity D -Category "cMDTDriver" -Type SET }

                # If file must be downloaded before imported
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath)_$($this.Version).zip' -Target $targetdownload -Verbose" -Severity D -Category "cMDTDriver" -Type SET }

                    # Start download
                    Invoke-WebDownload -Source "$($this.SourcePath)_$($this.Version).zip" -Target $targetdownload -Verbose

                    If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTDriver" -Type SET }

                    # Test if download was successfull
                    $present = Invoke-TestPath -Path $targetdownload

                    If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDriver" -Type SET }

                    # If download was not successfull
                    If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }
                }
                
                If ($this.Debug) { Invoke-Logger -Message "Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder" -Severity D -Category "cMDTApplication" -Type SET }

                # Expand archive
                Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $extractfolder" -Severity D -Category "cMDTDriver" -Type SET }

                # Check if expanded folder exist
                $present = Invoke-TestPath -Path $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDriver" -Type SET }

                # If expanded folder does not exist
                If (-not($present)) { Write-Error "Cannot find path '$extractfolder' because it does not exist." ; Return }

                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.path)\$($this.name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTApplication" -Type SET }

                # Remove current version
                Invoke-RemovePath -Path "$($this.path)\$($this.name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

                # If downloaded
                If ($download) {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $targetdownload" -Severity D -Category "cMDTDriver" -Type SET }

                    # Remove downloaded archive after expansion
                    Invoke-RemovePath -Path $targetdownload
                }

                # Call MDT import of new driver
                $this.ImportDriver($extractfolder)

                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $extractfolder" -Severity D -Category "cMDTDriver" -Type SET }

                # Remove expanded folder after import
                Invoke-RemovePath -Path $extractfolder
            }
            else
            {

                #  Import new driver

                If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path $($this.path) -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTDriver" -Type SET }

                # Create path for new driver import
                Invoke-CreatePath -Path $this.path -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

                If ($this.Debug) { Invoke-Logger -Message "Download: $download" -Severity D -Category "cMDTDriver" -Type SET }

                # If file must be downloaded before imported
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath)_$($this.Version).zip' -Target $targetdownload -Verbose" -Severity D -Category "cMDTDriver" -Type SET }

                    # Start download
                    Invoke-WebDownload -Source "$($this.SourcePath)_$($this.Version).zip" -Target $targetdownload -Verbose

                    If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTDriver" -Type SET }

                    # Test if download was successfull
                    $present = Invoke-TestPath -Path $targetdownload

                    If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDriver" -Type SET }

                    # If download was not successfull
                    If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }
                }
                
                If ($this.Debug) { Invoke-Logger -Message "Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder" -Severity D -Category "cMDTDriver" -Type SET }

                # Expand archive
                Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $extractfolder" -Severity D -Category "cMDTDriver" -Type SET }

                # Check if expanded folder exist
                $present = Invoke-TestPath -Path $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDriver" -Type SET }

                # If expanded folder does not exist
                If (-not($present)) { Write-Error "Cannot find path '$extractfolder' because it does not exist." ; Return }

                # If downloaded
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $targetdownload" -Severity D -Category "cMDTDriver" -Type SET }

                    # Remove downloaded archive after expansion
                    Invoke-RemovePath -Path $targetdownload
                }

                # Call MDT import of new driver
                $this.ImportDriver($extractfolder)

                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $extractfolder" -Severity D -Category "cMDTDriver" -Type SET }

                # Remove expanded folder after import
                Invoke-RemovePath -Path $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "New-ReferenceFile -Path $referencefile" -Severity D -Category "cMDTDriver" -Type SET }

                # Create new versioning file
                New-ReferenceFile -Path $referencefile
            }

            If ($this.Debug) { Invoke-Logger -Message "Set-Content -Path $referencefile -Value '$($this.Version)'" -Severity D -Category "cMDTDriver" -Type SET }

            # Set versioning file content
            Set-Content -Path $referencefile -Value "$($this.Version)"
        }
        else
        {
            # Remove existing driver
            
            If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.path)\$($this.name)' -Recurse -Levels 3 -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTDriver" -Type SET }

            # Remove application and traverse folder path where empty
            Invoke-RemovePath -Path "$($this.path)\$($this.name)" -Recurse -Levels 3 -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

            If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $referencefile" -Severity D -Category "cMDTDriver" -Type SET }

            # Remove reference file
            Invoke-RemovePath -Path $referencefile
        }
    }

    [bool] Test()
    {
        
        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.SourcePath

        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.path)\$($this.name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)" -Severity D -Category "cMDTDriver" -Type TEST }

        # Check if driver already exists in MDT
        $present = Invoke-TestPath -Path "$($this.path)\$($this.name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath 
        
        # If driver exists and should be present
        if (($present) -and ($this.ensure -eq [Ensure]::Present))
        {

            If ($this.Debug) { Invoke-Logger -Message "Compare-Version -Source '$($this.PSDrivePath)\Out-of-Box Drivers\$($($this.Path.Split('\')[-2]).Replace(' ',''))$($($this.Path.Split('\')[-1]).Replace(' ',''))$($($this.Name).Replace(' ',''))$($this.SourcePath.Split($separator)[-1]).version' -Target $($this.Version)" -Severity D -Category "cMDTDriver" -Type TEST }

            # Verify version against the reference file
            $match = Compare-Version -Source "$($this.PSDrivePath)\Out-of-Box Drivers\$($($this.Path.Split("\")[-2]).Replace(' ',''))$($($this.Path.Split("\")[-1]).Replace(' ',''))$($($this.Name).Replace(' ',''))$($this.SourcePath.Split($separator)[-1]).version" -Target $this.Version

            If ($this.Debug) { Invoke-Logger -Message "Match: $match" -Severity D -Category "cMDTDriver" -Type TEST }

            # If versioning file content do not match
            if (-not ($match))
            {
                Write-Verbose "$($this.Name) version has been updated on the pull server"
                $present = $false
            }
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

    [cMDTDriver] Get()
    {
        return $this
    }

    [void] ImportDriver($Driver)
    {

        If ($this.Debug) { Invoke-Logger -Message "Import-MicrosoftDeploymentToolkitModule" -Severity D -Category "cMDTDriver" -Type FUNCTION }

        # Import the required module MicrosoftDeploymentToolkitModule
        Import-MicrosoftDeploymentToolkitModule

        If ($this.Debug) { Invoke-Logger -Message "New-PSDrive -Name $($this.PSDriveName) -PSProvider 'MDTProvider' -Root $($this.PSDrivePath) -Verbose:$($false)" -Severity D -Category "cMDTDriver" -Type FUNCTION }

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        If ($this.Debug) { Invoke-Logger -Message "New-Item -Path $($this.Path) -enable $($this.Enabled) -Name $($this.Name) -Comments $($this.Comment) -ItemType 'folder' –Verbose" -Severity D -Category "cMDTDriver" -Type FUNCTION }

        # Create path for the driver
        New-Item -Path $this.Path -enable $this.Enabled -Name $this.Name -Comments $this.Comment -ItemType "folder" –Verbose

        If ($this.Debug) { Invoke-Logger -Message "Import-MDTDriver -Path '$($this.path)\$($this.name)' -SourcePath $Driver -ImportDuplicates -Verbose" -Severity D -Category "cMDTDriver" -Type FUNCTION }

        # Initialize driver import to MDT
        Import-MDTDriver -Path "$($this.path)\$($this.name)" -SourcePath $Driver -ImportDuplicates -Verbose

    }
}
