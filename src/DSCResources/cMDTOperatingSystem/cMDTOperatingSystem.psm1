enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTOperatingSystem
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty()]
    [string]$Version

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Key)]
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

        # Determine versioning type; checksum or static version
        [bool]$Hash = $False
        If (-not ($this.version))
        { $Hash = $True }

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.SourcePath

        $filename = $null

        # Set file name based on versioning type
        If ($Hash)
        {
            $filename = "$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).wim"
        }
        Else
        {
            $filename = "$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator))_$($this.Version).wim"
        }
        If ($this.Debug) { Invoke-Logger -Message "Download file: $filename" -Severity D -Category "cMDTOperatingSystem" -Type SET }
        
        # Set folder name as file name without version
        $foldername = (Get-FileNameFromPath -Path $this.SourcePath -Separator $separator).Split(".")[0]

        If ($this.Debug) { Invoke-Logger -Message "Folder name: $foldername" -Severity D -Category "cMDTOperatingSystem" -Type SET }

        # Determine if file path is an SMB or weblink and should be downloaded
        [bool]$download = $True
        If (($separator -eq "/") -Or ($this.SourcePath.Substring(0,2) -eq "\\"))
        {
            $targetdownload = "$($this.TempLocation)\$($filename)"

            If ($this.Debug) { Invoke-Logger -Message "Target download: $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

            $targetdownloadref = "$($this.TempLocation)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version"

            If ($this.Debug) { Invoke-Logger -Message "Target download reference: $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }
        }
        Else
        {
            If ($this.Debug) { Invoke-Logger -Message "Hash: $Hash" -Severity D -Category "cMDTOperatingSystem" -Type SET }
            If ($Hash)
            {
                $targetdownload = "$($this.SourcePath).wim"
                If ($this.Debug) { Invoke-Logger -Message "Target download: $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                $targetdownloadref = "$($this.SourcePath).version"
                If ($this.Debug) { Invoke-Logger -Message "Target download reference: $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }
            }
            Else
            {
                $targetdownload = "$($this.SourcePath)_$($this.Version).wim"
                If ($this.Debug) { Invoke-Logger -Message "Target download: $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                $targetdownloadref = "$($this.SourcePath)_$($this.Version).version"
                If ($this.Debug) { Invoke-Logger -Message "Target download reference: $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }
            }
            $download = $False
        }

        # Set reference file name to enable versioning
        $referencefile = "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version"

        If ($this.Debug) { Invoke-Logger -Message "Reference file: $referencefile" -Severity D -Category "cMDTOperatingSystem" -Type SET }

        # Set temporary extraction folder name
        $extractfolder = "$($this.TempLocation)\$($foldername)"

        If ($this.Debug) { Invoke-Logger -Message "Extract folder: $extractfolder" -Severity D -Category "cMDTOperatingSystem" -Type SET }

        # Determine if OS should be present or not
        if ($this.ensure -eq [Ensure]::Present)
        {

            If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)'" -Severity D -Category "cMDTOperatingSystem" -Type SET }

            # Check if OS already exist in MDT
            $present = Invoke-TestPath -Path "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)"

            if ($present)
            {

                # Upgrade existing OS

                If ($Hash)
                {
                    
                    # If checksum automatic update defined

                    If ($this.Debug) { Invoke-Logger -Message "Download: $download" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                    # If file must be downloaded before imported
                    If ($download)
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath).wim' -Target $targetdownload -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Start download of WIM
                        Invoke-WebDownload -Source "$($this.SourcePath).wim" -Target $targetdownload -Verbose

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if download was successfull
                        $present = Invoke-TestPath -Path $targetdownload

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If download was not successfull
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath).version' -Target $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Start download of checksum file
                        Invoke-WebDownload -Source "$($this.SourcePath).version" -Target $targetdownloadref

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if download was successfull
                        $present = Invoke-TestPath -Path $targetdownloadref

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If download of checksum was not successfull
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownloadref' because it does not exist." ; Return }

                    }
                    Else
                    {

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if WIM image can be found on source
                        $present = Invoke-TestPath -Path $targetdownload

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If image can not be found
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }

                    }
                }
                Else
                {

                    # If versioning update was defined

                    # If file must be downloaded before imported
                    If ($download)
                    {

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath)_$($this.Version).wim' -Target $targetdownload -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Start download of WIM
                        Invoke-WebDownload -Source "$($this.SourcePath)_$($this.Version).wim" -Target $targetdownload -Verbose

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if download was successfull
                        $present = Invoke-TestPath -Path $targetdownload

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If download was not successfull
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }

                    }
                }

                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)' -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }
                
                # Remove existing OS file
                Invoke-RemovePath -Path "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)" -Verbose

                If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)'" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                # Test if removal was successfull
                $present = Invoke-TestPath -Path "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)"

                If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                # If removal was unsuccessfull
                If ($present) { Write-Error "Could not remove path '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)'." ; Return }

                # Define new file names for import. Needed to keep names intact in MDT when not performing a new import.
                $oldname = $null
                $newname = $null
                If (-not ($Hash))
                {
                    $oldname = $targetdownload
                    $newname = $targetdownload.Replace("_$($this.Version)","")
                }

                # If file must be downloaded before imported
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Copy-Item $targetdownload -Destination '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)' -Force -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                    # Copy WIM file to MDT storage location
                    Copy-Item $targetdownload -Destination "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)" -Force -Verbose
                }
                Else
                {
                    If (-not ($Hash))
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Rename-Item -Path $oldname -NewName $newname -ErrorAction SilentlyContinue -Verbose:$($False)" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Rename file for import
                        Rename-Item -Path $oldname -NewName $newname -ErrorAction SilentlyContinue -Verbose:$False
                    }
                    If ($Hash)
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Copy-Item $targetdownload -Destination '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)' -Force -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Copy WIM file to MDT storage location
                        Copy-Item $targetdownload -Destination "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)" -Force -Verbose
                    }
                    Else
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Copy-Item $newname -Destination '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)' -Force -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Copy renamed WIM file to MDT storage location
                        Copy-Item $newname -Destination "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$($filename)" -Force -Verbose
                    }
                    If (-not ($Hash))
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Rename-Item -Path $newname -NewName $oldname -ErrorAction SilentlyContinue -Verbose:$($False)" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Rename source file to back original name
                        Rename-Item -Path $newname -NewName $oldname -ErrorAction SilentlyContinue -Verbose:$False
                    }
                }

                If ($Hash)
                {

                    # Get versioning from downloaded checksum
                    $this.version = Get-Content -Path $targetdownloadref

                    If ($this.Debug) { Invoke-Logger -Message "Version: $($this.version)" -Severity D -Category "cMDTOperatingSystem" -Type SET }
                }

                If ($this.Debug) { Invoke-Logger -Message "Set-Content -Path $referencefile -Value '$($this.Version)' -Verbose:$($false)" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                # Set versioning content to reference file
                Set-Content -Path $referencefile -Value "$($this.Version)" -Verbose:$false
            }
            else
            {

                # Import new OS

                If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path '$($this.Path)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                # Create path for new OS import
                Invoke-CreatePath -Path "$($this.Path)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
                
                # Define new file names for import. Needed to keep names intact in MDT when not performing a new import.
                $oldname = $null
                $newname = $null
                If (-not ($Hash))
                {
                    $oldname = $targetdownload
                    $newname = $targetdownload.Replace("_$($this.Version)","")
                }

                # If file must be downloaded before imported
                If ($download)
                {

                    # If file must be downloaded before imported

                    If ($this.Debug) { Invoke-Logger -Message "Hash: $Hash" -Severity D -Category "cMDTOperatingSystem" -Type SET }
                    If ($Hash)
                    {
                        
                        # If checksum update was defined

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath).wim' -Target $targetdownload -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Download WIm file
                        Invoke-WebDownload -Source "$($this.SourcePath).wim" -Target $targetdownload -Verbose

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if download was successfull
                        $present = Invoke-TestPath -Path $targetdownload

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If download was not successfull
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath).version' -Target $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Download checksum file
                        Invoke-WebDownload -Source "$($this.SourcePath).version" -Target $targetdownloadref

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if download was successfull
                        $present = Invoke-TestPath -Path $targetdownloadref

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If download was not successfull
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownloadref' because it does not exist." ; Return }

                    }
                    Else
                    {

                        # If versioning update was defined

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath)_$($this.Version).wim' -Target $targetdownload -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Download WIM file
                        Invoke-WebDownload -Source "$($this.SourcePath)_$($this.Version).wim" -Target $targetdownload -Verbose

                        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Test if download was successfull
                        $present = Invoke-TestPath -Path $targetdownload

                        If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # If download was not successfull
                        If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }

                    }

                    # Call function to import OS
                    $this.ImportOperatingSystem($targetdownload)
                }
                Else
                {

                    # If file must not be downloaded before imported

                    If (-not ($Hash))
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Rename-Item -Path $oldname -NewName $newname -ErrorAction SilentlyContinue -Verbose:$($False)" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Rename file for import
                        Rename-Item -Path $oldname -NewName $newname -ErrorAction SilentlyContinue -Verbose:$False
                    }
                    If ($Hash)
                    {

                        # Call function to import OS
                        $this.ImportOperatingSystem($targetdownload)
                    }
                    Else
                    {

                        # Call function to import OS
                        $this.ImportOperatingSystem($newname)
                    }
                    If (-not ($Hash))
                    {
                        If ($this.Debug) { Invoke-Logger -Message "Rename-Item -Path $newname -NewName $oldname -ErrorAction SilentlyContinue -Verbose:$($False)" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                        # Rename file after import
                        Rename-Item -Path $newname -NewName $oldname -ErrorAction SilentlyContinue -Verbose:$False
                    }
                }

                If ($this.Debug) { Invoke-Logger -Message "New-ReferenceFile -Path $referencefile -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                # Create new reference file for versioning
                New-ReferenceFile -Path $referencefile -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath

                If ($Hash)
                {

                    # Get checksum from downloaded file
                    $this.version = Get-Content -Path $targetdownloadref

                    If ($this.Debug) { Invoke-Logger -Message "Version: $($this.version)" -Severity D -Category "cMDTOperatingSystem" -Type SET }
                }

                If ($this.Debug) { Invoke-Logger -Message "Set-Content -Path $referencefile -Value '$($this.Version)'" -Severity D -Category "cMDTOperatingSystem" -Type SET }

                # Set versioning file content
                Set-Content -Path $referencefile -Value "$($this.Version)"
            }
        }
        else
        {

            # Remove existing OS

            If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.Path)' -Recurse -Levels 4 -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type SET }

            # Remove OS recursively from MDT
            Invoke-RemovePath -Path "$($this.Path)" -Recurse -Levels 4 -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

            If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.PSDrivePath)\Operating Systems\$($this.Name)'" -Severity D -Category "cMDTOperatingSystem" -Type SET }

            # Test if renmoval was successfull
            $present = Invoke-TestPath -Path "$($this.PSDrivePath)\Operating Systems\$($this.Name)"

            If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type SET }

            # If removal was not successfull
            If ($present) { Write-Error "Cannot find path '$($this.PSDrivePath)\Operating Systems\$($this.Name)' because it does not exist." }

        }

    }

    [bool] Test()
    {

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.SourcePath

        # Determine if checksum or manual versioning update was defined
        If (-not ($this.version))
        {

            # Determine versioning file must be downloaded
            [bool]$download = $True
            If (($separator -eq "/") -Or ($this.SourcePath.Substring(0,2) -eq "\\"))
            {
                $targetdownloadref = "$($this.TempLocation)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version"
            }
            Else
            {
                $targetdownloadref = "$($this.SourcePath).version"
                $download = $False
            }
            If ($this.Debug) { Invoke-Logger -Message "Target download reference: $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

            If ($this.Debug) { Invoke-Logger -Message "Download: $download" -Severity D -Category "cMDTOperatingSystem" -Type TEST }
            If ($download)
            {
                If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.SourcePath).version' -Target $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

                # Download versioning file
                Invoke-WebDownload -Source "$($this.SourcePath).version" -Target $targetdownloadref

                If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownloadref" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

                # Test if download was successfull
                $present = Invoke-TestPath -Path $targetdownloadref
                If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

                # If download was not successfull
                If (-not($present)) { Write-Error "Cannot find path '$targetdownloadref' because it does not exist." ; Exit }
            }

            # Get content from downloaded versioning file
            $this.version = Get-Content -Path $targetdownloadref

            If ($this.Debug) { Invoke-Logger -Message "Version: $($this.version)" -Severity D -Category "cMDTOperatingSystem" -Type TEST }
        }

        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).wim'" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

        # Test if OS file already exist in MDT
        $present = Invoke-TestPath -Path "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).wim"

        # If OS exists and should be present
        if (($present) -and ($this.ensure -eq [Ensure]::Present))
        {
            If ($this.Debug) { Invoke-Logger -Message "Compare-Version -Source '$($this.PSDrivePath)\Operating Systems\$($this.Name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version' -Target $($this.Version)" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

            # Verify content from server side versioning file against local reference file
            $match = Compare-Version -Source "$($this.PSDrivePath)\Operating Systems\$($this.Name)\$((Get-FileNameFromPath -Path $this.SourcePath -Separator $separator)).version" -Target $this.Version

            If ($this.Debug) { Invoke-Logger -Message "Match: $match" -Severity D -Category "cMDTOperatingSystem" -Type TEST }

            if (-not ($match))
            {

                # If version does not match
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

    [cMDTOperatingSystem] Get()
    {
        return $this
    }

    [void] ImportOperatingSystem($OperatingSystem)
    {

        If ($this.Debug) { Invoke-Logger -Message "Import-MicrosoftDeploymentToolkitModule" -Severity D -Category "cMDTOperatingSystem" -Type FUNCTION }

        # Import the MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        If ($this.Debug) { Invoke-Logger -Message "New-PSDrive -Name $($this.PSDriveName) -PSProvider 'MDTProvider' -Root $($this.PSDrivePath) -Verbose:$($false)" -Severity D -Category "cMDTOperatingSystem" -Type FUNCTION }

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        # Verify that the path for the application import exist
        If (-not(Invoke-TestPath -Path $this.Path -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath))
        {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path $($this.Path) -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type FUNCTION }

            # Create folder path to prepare for OS import
            Invoke-CreatePath -Path $this.Path -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
        }

        Try
        {
            
            $ErrorActionPreference = "Stop"

            If ($this.Debug) { Invoke-Logger -Message "Import-MDTOperatingSystem -Path $($this.Path) -SourceFile $OperatingSystem -DestinationFolder $($this.Name) -Verbose" -Severity D -Category "cMDTOperatingSystem" -Type FUNCTION }

            # Start import of OS file
            Import-MDTOperatingSystem -Path $this.Path -SourceFile $OperatingSystem -DestinationFolder $this.Name -Verbose

            $ErrorActionPreference = "Continue"
        }
            Catch [Microsoft.Management.Infrastructure.CimException]
            {
                If ($_.FullyQualifiedErrorId -notlike "*ItemAlreadyExists*")
                {
                    throw $_
                }
            }
            Finally
            {
                
            }
        }
}
