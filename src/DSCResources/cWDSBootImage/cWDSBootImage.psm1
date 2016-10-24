enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cWDSBootImage
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty(Key)]
    [string]$Version

    [DscProperty(Key)]
    [string]$ImageName

    [void] Set()
    {

        if ($this.Ensure -eq [Ensure]::Present)
        {
            $this.AddBootImage()
        }
        else
        {
            $this.RemoveBootImage()
        }
    }

    [bool] Test()
    {
        Return ($this.VerifyVersion())
    }

    [cWDSBootImage] Get()
    {
        return $this
    }

    [bool] VerifyVersion()
    {
        [bool]$match = $false

        $foldername = $this.Path.Replace("\$($this.Path.Split("\")[-1])","")

        if ((Get-Content -Path "$($foldername)\WSDBootImage.version" -ErrorAction Ignore) -eq $this.Version)
        {
            $match = $true
        }
        
        return $match
    }

    [bool] DoesBootImageExist()
    {
      #BAD Implementation:  return ((Get-WdsBootImage -ImageName $this.ImageName) -ne $null)
      return ($null -ne (Get-WdsBootImage -ImageName $this.ImageName))
    }

    [void] AddBootImage()
    {
        If ($this.DoesBootImageExist()) { $this.RemoveBootImage() }

        Import-WdsBootImage -Path $this.Path -NewImageName $this.ImageName –SkipVerify | Out-Null

        $foldername = $this.Path.Replace("\$($this.Path.Split("\")[-1])","")

        if (-not (Get-Content -Path "$($foldername)\WSDBootImage.version" -ErrorAction Ignore))
        {
            New-ReferenceFile -Path "$($foldername)\WSDBootImage.version"
        }

        Set-Content -Path "$($foldername)\WSDBootImage.version" -Value "$($this.Version)"
    }
    
    [void] RemoveBootImage()
    {
        Get-WdsBootImage -ImageName $this.ImageName | Remove-WdsBootImage
    }
    
}
