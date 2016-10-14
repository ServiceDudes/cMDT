enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTCustomSettingsIni
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty()]
    [string]$Content

    [void] Set()
    {
        
        # Check if defined as present
        if ($this.Ensure -eq [Ensure]::Present)
        {
            # If set to present set content according to contract
            $this.SetContent()
        }
        else
        {
            # If set to absent revert to default content
            $this.SetDefaultContent()
        }
    }

    [bool] Test()
    {

        # Call function to test file content according to contract
        $present = $this.TestFileContent()
        
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTCustomSettingsIni] Get()
    {
        return $this
    }

    [bool] TestFileContent()
    {
        $present = $false

        # Import existing file content
        $existingConfiguration = Get-Content -Path $this.Path -Raw #-Encoding UTF8

        # Match against content from contract
        if ($existingConfiguration -eq $this.Content.Replace("`n","`r`n"))
        {
            $present = $true   
        }

        return $present
    }

    [void] SetContent()
    {
        # Set new file content
        Set-Content -Path $this.Path -Value $this.Content.Replace("`n","`r`n") -NoNewline -Force #-Encoding UTF8
    }
    
    [void] SetDefaultContent()
    {
        # Set default content
        $defaultContent = @"
[Settings]
Priority=Default
Properties=MyCustomProperty

[Default]
OSInstall=Y
SkipCapture=YES
SkipAdminPassword=NO
SkipProductKey=YES

"@
        Set-Content -Path $this.Path -Value $defaultContent -NoNewline -Force #-Encoding UTF8
    }
}
