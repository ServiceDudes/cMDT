enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTPreReqs
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty()] 
    [string]$Name

    [DscProperty()] 
    [string]$ProductId

    [DscProperty()] 
    [string]$SourcePath
    
    [DscProperty(Key)]
    [string]$DownloadPath
    
    [void] Set()
    {

        Write-Verbose "Starting set for $($this.Name)..."

        $file = ($this.DownloadPath).split("\")[-1]
        $path = ($this.DownloadPath).Replace("\$($file)","")

        if ($this.ensure -eq [Ensure]::Present)
        {

            $present = Invoke-TestPath -Path $path

            if (-not($present)) { New-Item -Path $this.DownloadPath -ItemType Directory -Force }

            $fileName = $null
            $fileExist = Invoke-TestPath -Path $this.DownloadPath
            If (-not($fileExist)) { $fileName = (Get-ChildItem -Path $path -Filter "$($file.split("_")[0])*.$($file.split(".")[-1])" -ErrorAction SilentlyContinue).Name}
            Else { $fileName = $file }

            If ($fileName -and (Test-Path -Path "$($path)\$($fileName)")) { Remove-Item -Path "$($path)\$($fileName)" -Force }
            If (-not(Invoke-TestPath -Path $path)) { New-Item -Path $path -ItemType Directory -Force }

            Invoke-WebDownload -Source $this.SourcePath -Target $this.DownloadPath -Verbose

            if($this.Name -eq "modelalias"){
                Invoke-ExpandArchive -Source $this.DownloadPath -Target $path
                Invoke-RemovePath -Path $this.DownloadPath
            }
            
        }
        else
        {
            Invoke-RemovePath -Path $path
        }

    }

    [bool] Test()
    {

        Write-Verbose "Testing for $($this.Name)..."

        $file = ($this.DownloadPath).split("\")[-1]
        $path = ($this.DownloadPath).Replace("\$($file)","")

        $present = Invoke-TestPath -Path $path

        if ($this.ensure -eq [Ensure]::Present)
        {

            if (-not($present)) { Write-Verbose "   Download path not found" ; return $present }
            
            $fileExist = (Invoke-TestPath -Path $this.DownloadPath)
            If (-not($fileExist))
            {
                $fileName = (Get-ChildItem -Path $path -Filter "$($file.split("_")[0])*.$($file.split(".")[-1])" -ErrorAction SilentlyContinue).Name
                If ($fileName -and (Invoke-TestPath -Path $fileName)) { $file = $fileName ; $present = $true }
            }
            
            If ($file.split(".")[-1].ToLower() -eq "msi")
            {
                [string]$msiProductCode = Get-MsiProperty -Path "$($path)\$($file)" -Property ProductCode
                Try { $msiProductCode = $msiProductCode -split '\s+' -match '\S' }
                catch {
                    Write-Verbose "   Failed to find product code!"
                }
                If ($msiProductCode -ne $this.ProductId)
                {
                    Write-Verbose "   ProductCode mismatch. Upgrade detected."
                    $Present = $false
                }
            }

        }
        else{
            if ($Present){
               $present = $false 
            }
            else{
               $present = $true 
            }
        }

        return $present

    }

    [cMDTPreReqs] Get()
    {
        return $this
    }

}
