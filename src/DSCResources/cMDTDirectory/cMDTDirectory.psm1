enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTDirectory
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Key)]
    [string]$Name

    [DscProperty()]
    [string]$PSDriveName

    [DscProperty()]
    [string]$PSDrivePath

    [DscProperty()]
    [bool]$Debug

    [void] Set()
    {
        
        # Determine present/absent
        if ($this.ensure -eq [Ensure]::Present)
        {
            # If present create path
            $this.CreateDirectory()
        }
        else
        {
            # Verify if local path or PSDrive
            if (($this.PSDrivePath) -and ($this.PSDriveName))
            {
                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.path)\$($this.Name)' -Recurse -Levels 4 -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTDirectory" -Type SET }

                # Remove and traverse folder path where empty
                Invoke-RemovePath -Path "$($this.path)\$($this.Name)" -Recurse -Levels 4 -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose
            }
            Else
            {
                If ($this.Debug) { Invoke-Logger -Message "Invoke-RemovePath -Path '$($this.path)\$($this.Name)' -Recurse -Levels 4 -Verbose" -Severity D -Category "cMDTDirectory" -Type SET }

                # Remove and traverse folder path where empty
                Invoke-RemovePath -Path "$($this.path)\$($this.Name)" -Recurse -Levels 4 -Verbose
            }
        }
    }

    [bool] Test()
    {

        # Verify if local path or PSDrive
        if (($this.PSDrivePath) -and ($this.PSDriveName))
        {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.path)\$($this.Name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTDirectory" -Type TEST }

            # Verify if PSDrive path exist
            $present = Invoke-TestPath -Path "$($this.path)\$($this.Name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

            If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDirectory" -Type TEST }
        }
        Else
        {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-TestPath -Path '$($this.path)\$($this.Name)' -Verbose" -Severity D -Category "cMDTDirectory" -Type TEST }

            # Verify if local path exist
            $present = Invoke-TestPath -Path "$($this.path)\$($this.Name)" -Verbose

            If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDirectory" -Type TEST }
        }
        
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTDirectory] Get()
    {
        return $this
    }

    [void] CreateDirectory()
    {

        # Verify if local path or PSDrive
        if (($this.PSDrivePath) -and ($this.PSDriveName))
        {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path '$($this.path)\$($this.Name)' -PSDriveName $($this.PSDriveName) -PSDrivePath $($this.PSDrivePath) -Verbose" -Severity D -Category "cMDTDirectory" -Type FUNCTION }

            # Create PSDrive path
            $present = Invoke-CreatePath -Path "$($this.path)\$($this.Name)" -PSDriveName $this.PSDriveName -PSDrivePath $this.PSDrivePath -Verbose

            If ($this.Debug) { Invoke-Logger -Message "Return: $present" -Severity D -Category "cMDTDirectory" -Type FUNCTION }
        }
        Else
        {
            If ($this.Debug) { Invoke-Logger -Message "Invoke-CreatePath -Path '$($this.path)\$($this.Name)' -Verbose" -Severity D -Category "cMDTDirectory" -Type FUNCTION }

            # Create local path
            Invoke-CreatePath -Path "$($this.path)\$($this.Name)" -Verbose
        }

    }

}
