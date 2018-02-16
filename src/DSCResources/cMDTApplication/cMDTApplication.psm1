enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTApplication
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Key)]
    [string]$ShortName

    [DscProperty(Mandatory)]
    [string]$Version

    [DscProperty(Mandatory)]
    [string]$Publisher

    [DscProperty(Mandatory)]
    [string]$Language
    
    [DscProperty(Mandatory)]
    [string]$CommandLine
    
    [DscProperty(Mandatory)]
    [string]$WorkingDirectory
    
    [DscProperty(Mandatory)]
    [string]$ApplicationSourcePath
    
    [DscProperty(Mandatory)]
    [string]$TempLocation

    [DscProperty(Mandatory)]
    [string]$DestinationFolder
    
    [DscProperty(Mandatory)]
    [string]$Enabled

    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [DscProperty()]
    [bool]$Debug

    [void] Set()
    {

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.ApplicationSourcePath

        # Set file name based on name, version and type
        $filename = "$((Get-FileNameFromPath -Path $this.ApplicationSourcePath -Separator $separator))_$($this.Version).zip"

        If ($this.Debug) { Invoke-Logger -Message "Download file: $filename" -Severity D -Category "cMDTApplication" -Type SET }

        # Set folder name as file name without version
        $foldername = (Get-FileNameFromPath -Path $this.ApplicationSourcePath -Separator $separator).Split(".")[0]

        If ($this.Debug) { Invoke-Logger -Message "Folder name: $foldername" -Severity D -Category "cMDTApplication" -Type SET }

        # Determine if file path is an SMB or weblink and should be downloaded
        [bool]$download = $True
        If (($separator -eq "/") -Or ($this.ApplicationSourcePath.Substring(0,2) -eq "\\"))
        { $targetdownload = "$($this.TempLocation)\$($filename)" }
        Else
        { $targetdownload = "$($this.ApplicationSourcePath)_$($this.Version).zip" ; $download = $False }
        If ($this.Debug) { Invoke-Logger -Message "Target download: $targetdownload" -Severity D -Category "cMDTApplication" -Type SET }
        
        # Set temporary extraction folder name
        $extractfolder = "$($this.TempLocation)\$($foldername)"

        If ($this.Debug) { Invoke-Logger -Message "Extract folder: $extractfolder" -Severity D -Category "cMDTApplication" -Type SET }

        # Set reference file name to enable versioning
        $referencefile = "$($this.PSDrivePath)\Applications\$($this.DestinationFolder)\$((Get-FileNameFromPath -Path $this.ApplicationSourcePath -Separator $separator)).version"

        If ($this.Debug) { Invoke-Logger -Message "Reference file: $referencefile" -Severity D -Category "cMDTApplication" -Type SET }

        # Determine if application should be present or not
        if ($this.ensure -eq [Ensure]::Present)
        {

            If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.path)\$($this.name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)" -Severity D -Category "cMDTApplication" -Type SET }

            # Check if application already exist in MDT
            $present = Invoke-TestPath -Path "$($this.path)\$($this.name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath

            If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTApplication" -Type SET }

            if ($present)
            {

                #  Upgrade existing application

                If ($this.Debug) { Invoke-Logger -Message "Download: $download" -Severity D -Category "cMDTApplication" -Type SET }

                # If file must be downloaded before imported
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.ApplicationSourcePath)_$($this.Version).zip'" -Severity D -Category "cMDTApplication" -Type SET }

                    # Start download
                    Invoke-WebDownload -Source "$($this.ApplicationSourcePath)_$($this.Version).zip" -Target $targetdownload -Verbose

                    If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTApplication" -Type SET }

                    # Test if download was successfull
                    $present = Invoke-TestPath -Path $targetdownload

                    If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTApplication" -Type SET }

                    # If download was not successfull
                    If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }
                }

                If ($this.Debug) { Invoke-Logger -Message "Invoke-ExpandArchive -Source $targetdownload -Target '$($this.PSDrivePath)\Applications\$($this.DestinationFolder)'" -Severity D -Category "cMDTApplication" -Type SET }

                # Expand archive to application folder in MDT
                Invoke-ExpandArchive -Source $targetdownload -Target "$($this.PSDrivePath)\Applications\$($this.DestinationFolder)"

                # If downloaded
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $targetdownload" -Severity D -Category "cMDTApplication" -Type SET }

                    # Remove downloaded archive after expansion
                    Invoke-RemovePath -Path $targetdownload
                }
            }
            else
            {

                #  Import new application

                If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path $($this.path) -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTApplication" -Type SET }

                # Create path for new application import
                Invoke-CreatePath -Path $this.path -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

                If ($this.Debug) { Invoke-Logger -Message "Download: $download" -Severity D -Category "cMDTApplication" -Type SET }

                # If file must be downloaded before imported
                If ($download)
                {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-WebDownload -Source '$($this.ApplicationSourcePath)_$($this.Version).zip'" -Severity D -Category "cMDTApplication" -Type SET }

                    # Start download of application
                    Invoke-WebDownload -Source "$($this.ApplicationSourcePath)_$($this.Version).zip" -Target $targetdownload -Verbose

                    If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $targetdownload" -Severity D -Category "cMDTApplication" -Type SET }

                    # Test if download was successfull
                    $present = Invoke-TestPath -Path $targetdownload

                    If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTApplication" -Type SET }

                    # If download was not successfull
                    If (-not($present)) { Write-Error "Cannot find path '$targetdownload' because it does not exist." ; Return }
                }

                If ($this.Debug) { Invoke-Logger -Message "Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder" -Severity D -Category "cMDTApplication" -Type SET }

                # Expand archive
                Invoke-ExpandArchive -Source $targetdownload -Target $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path $extractfolder" -Severity D -Category "cMDTApplication" -Type SET }

                # Check if expanded folder exist
                $present = Invoke-TestPath -Path $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTApplication" -Type SET }

                # If expanded folder does not exist
                If (-not($present)) { Write-Error "Cannot find path '$extractfolder' because it does not exist." ; Return }

                # If downloaded
                If ($download) {
                    If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $targetdownload" -Severity D -Category "cMDTApplication" -Type SET }
                    
                    # Remove downloaded archive after expansion
                    Invoke-RemovePath -Path $targetdownload
                }

                # Call MDT import of new application
                $this.ImportApplication($extractfolder)

                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path $extractfolder" -Severity D -Category "cMDTApplication" -Type SET }

                # Remove expanded folder after import
                Invoke-RemovePath -Path $extractfolder

                If ($this.Debug) { Invoke-Logger -Message "New-ReferenceFile -Path $referencefile -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)" -Severity D -Category "cMDTApplication" -Type SET }

                # Create new versioning file
                New-ReferenceFile -Path $referencefile -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath
            }

            If ($this.Debug) { Invoke-Logger -Message "Set-Content -Path $referencefile -Value $($this.Version)" -Severity D -Category "cMDTApplication" -Type SET }

            # Set versioning file content
            Set-Content -Path $referencefile -Value "$($this.Version)"
        }
        else
        {

            # Remove existing application

            If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.path)\$($this.name)' -Recurse -Levels 3 -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTApplication" -Type SET }

            # Remove application and traverse folder path where empty
            Invoke-RemovePath -Path "$($this.path)\$($this.name)" -Recurse -Levels 3 -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
        }
    }

    [bool] Test()
    {

        # Get string path separator; eg. "/" or "\"
        [string]$separator = Get-Separator -Path $this.ApplicationSourcePath

        If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.path)\$($this.name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)" -Severity D -Category "cMDTApplication" -Type TEST }

        # Check if application already exists in MDT
        $present = Invoke-TestPath -Path "$($this.path)\$($this.name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath 

        # If application exists and should be present
        if (($present) -and ($this.ensure -eq [Ensure]::Present))
        {
            If ($this.Debug) { Invoke-Logger -Message "Compare-Version -Source '$($this.PSDrivePath)\Applications\$($this.DestinationFolder)\$($this.ApplicationSourcePath.Split($($separator))[-1]).version' -Target $($this.Version)" -Severity D -Category "cMDTApplication" -Type TEST }

            # Verify version against the reference file
            $match = Compare-Version -Source "$($this.PSDrivePath)\Applications\$($this.DestinationFolder)\$((Get-FileNameFromPath -Path $this.ApplicationSourcePath -Separator $separator)).version" -Target $this.Version

            If ($this.Debug) { Invoke-Logger -Message "Match: $match" -Severity D -Category "cMDTApplication" -Type TEST }

            # If versioning file content do not match
            if (-not ($match))
            {
                If ($this.Debug) { Invoke-Logger -Message "$($this.Name) version has been updated on the pull server" -Severity D -Category "cMDTApplication" -Type TEST }
                Write-Verbose "$($this.Name) version has been updated on the pull server"
                $present = $false
            }
        }

        # Return boolean from test method
        if ($this.Ensure -eq [Ensure]::Present)
        {
            If ($this.Debug) { Invoke-Logger -Message "Return $present" -Severity D -Category "cMDTApplication" -Type TEST }
            return $present
        }
        else
        {
            If ($this.Debug) { Invoke-Logger -Message "Return -not $present" -Severity D -Category "cMDTApplication" -Type TEST }
            return -not $present
        }
    }

    [cMDTApplication] Get()
    {
        return $this
    }

    [void] ImportApplication($Source)
    {

        If ($this.Debug) { Invoke-Logger -Message "Import-MicrosoftDeploymentToolkitModule" -Severity D -Category "cMDTApplication" -Type FUNCTION }

        # Import the required module MicrosoftDeploymentToolkitModule
        Import-MicrosoftDeploymentToolkitModule

        If ($this.Debug) { Invoke-Logger -Message "New-PSDrive -Name $($this.PSDriveName) -PSProvider 'MDTProvider' -Root $($this.PSDrivePath) -Verbose:$($false)" -Severity D -Category "cMDTApplication" -Type FUNCTION }

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        If ($this.Debug) { Invoke-Logger -Message "If (-not(Invoke-TestPath -Path $($this.path) -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath)))" -Severity D -Category "cMDTApplication" -Type FUNCTION }

        # Verify that the path for the application import exist
        If (-not(Invoke-TestPath -Path $this.path -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath))
        {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path $($this.path) -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTApplication" -Type FUNCTION }

            # Create folder path to prepare for application import
            Invoke-CreatePath -Path $this.path -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
        }

        If ($this.Debug) { Invoke-Logger -Message "Import-MDTApplication -Path $($this.Path) -Enable $($this.Enabled) -Name $($this.Name) -ShortName $($this.ShortName) -Version $($this.Version) -Publisher $($this.Publisher) -Language $($this.Language) -CommandLine $($this.CommandLine) -WorkingDirectory $($this.WorkingDirectory) -ApplicationSourcePath $($Source) -DestinationFolder $($this.DestinationFolder) -Verbose" -Severity D -Category "cMDTApplication" -Type FUNCTION }   

        # Initialize application import to MDT
        Import-MDTApplication -Path $this.Path -Enable $this.Enabled -Name $this.Name -ShortName $this.ShortName -Version $this.Version `
                              -Publisher $this.Publisher -Language $this.Language -CommandLine $this.CommandLine -WorkingDirectory $this.WorkingDirectory `                              -ApplicationSourcePath $Source -DestinationFolder $this.DestinationFolder -Verbose

    }
}
