enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTPreReqs
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure
    
    [DscProperty(Key)]
    [string]$DownloadPath

    [DscProperty(Mandatory)] 
    [hashtable]$Prerequisites
    
    [void] Set()
    {
        Write-Verbose "Starting Set MDT PreReqs..."

        if ($this.ensure -eq [Ensure]::Present)
        {
            $present = $this.TestDownloadPath()

            if ($present){
                Write-Verbose "   Download folder present!"
            }
            else{
                New-Item -Path $this.DownloadPath -ItemType Directory -Force
            }

            [string]$separator = ""
            If ($this.DownloadPath -like "*/*")
            { $separator = "/" }
            Else
            { $separator = "\" }
            
            #Set all files:               
            ForEach ($file in $this.Prerequisites)
            {
                if($file.MDT){                     
                    if(Test-Path -Path "$($this.DownloadPath)\Microsoft Deployment Toolkit"){
                        Write-Verbose "   MDT already present!"
                    }
                    Else{
                        Write-Verbose "   Creating MDT folder..."
                        New-Item -Path "$($this.DownloadPath)\Microsoft Deployment Toolkit" -ItemType Directory -Force
                        $this.WebClientDownload($file.MDT, "$($this.DownloadPath)\Microsoft Deployment Toolkit\MicrosoftDeploymentToolkit2013_x64.msi")
                    }
                }

                if($file.ADK){                     
                    if(Test-Path -Path "$($this.DownloadPath)\Windows Assessment and Deployment Kit"){
                        Write-Verbose "   ADK folder already present!"
                    }
                    Else{
                        Write-Verbose "   Creating ADK folder..."
                        New-Item -Path "$($this.DownloadPath)\Windows Assessment and Deployment Kit" -ItemType Directory -Force
                        $this.WebClientDownload($file.ADK,"$($this.DownloadPath)\Windows Assessment and Deployment Kit\adksetup.exe")
                        #Run setup to prepp files...
                    }
                }

                <#
                if($file.SQL){                     
                    if(Test-Path -Path "$($this.DownloadPath)\Microsoft SQL Server 2014 Express"){
                        Write-Verbose "   SQL folder already present!"
                    }
                    Else{
                        Write-Verbose "   Creating SQL folder..."
                        New-Item -Path "$($this.DownloadPath)\Microsoft SQL Server 2014 Express" -ItemType Directory -Force
                        $this.WebClientDownload($file.SQL,"$($this.DownloadPath)\Microsoft SQL Server 2014 Express\SQLEXPR_x64_ENU.exe")
                    }
                }
                #>

                if(Test-Path -Path "$($this.DownloadPath)\Community"){
                    Write-Verbose "   Community folder already present!"
                }
                Else{
                    Write-Verbose "   Creating Community folder..."
                    New-Item -Path "$($this.DownloadPath)\Community" -ItemType Directory -Force
                    New-Item -Path "$($this.DownloadPath)\Community\Scripts" -ItemType Directory -Force
                    New-Item -Path "$($this.DownloadPath)\Community\Control" -ItemType Directory -Force
                    New-Item -Path "$($this.DownloadPath)\Community\PEextraFiles" -ItemType Directory -Force
                }

                if($file.C01){
                    #ToDo: Need test for all files...                  
                    $this.WebClientDownload($file.C01,"$($this.DownloadPath)\Community\modelalias.zip")
                    $this.ExtractFile("$($this.DownloadPath)\Community\modelalias.zip","$($this.DownloadPath)\Community")
                    Move-Item "$($this.DownloadPath)\Community\ModelAlias\ModelAliasExit.vbs" "$($this.DownloadPath)\Community\Scripts"
                    Remove-Item -Path "$($this.DownloadPath)\Community\ModelAlias" -Force
                    Remove-Item -Path "$($this.DownloadPath)\Community\modelalias.zip" -Force
                }
            }
            
            
        }
        else
        {
            $this.RemoveDirectory("")
        }

        Write-Verbose "MDT PreReqs set completed!"
    }

    [bool] Test()
    {
        Write-Verbose "Testing MDT PreReqs..."
        $present = $this.TestDownloadPath()

        if ($this.ensure -eq [Ensure]::Present)
        {            
            Write-Verbose "   Testing for download path.."            
            if($present){
                Write-Verbose "   Download path found!"}            
            Else{
                Write-Verbose "   Download path not found!"
                return $present }

            ForEach ($File in $this.Prerequisites)
            {
               if($file.MDT){
                 Write-Verbose "   Testing for MDT..."                
                 $present = (Test-Path -Path "$($this.DownloadPath)\Microsoft Deployment Toolkit\MicrosoftDeploymentToolkit2013_x64.msi")
                 Write-Verbose "   $present"
                 if($Present){}Else{return $false}
               }
               
               if($file.ADK){
                 Write-Verbose "   Testing for ADK..."                 
                 $present = (Test-Path -Path "$($this.DownloadPath)\Windows Assessment and Deployment Kit\adksetup.exe")
                 Write-Verbose "   $present"
                 if($Present){}Else{return $false}   
               }

               <#
               if($file.SQL){
                 Write-Verbose "   Testing for SQL..."                 
                 $present = (Test-Path -Path "$($this.DownloadPath)\Microsoft SQL Server 2014 Express\SQLEXPR_x64_ENU.exe")
                 Write-Verbose "   $present"
                 if($Present){}Else{return $false}   
               }
               #>

               if($file.C01){
                 Write-Verbose "   Testing for Community Script: ModelAlias.vbs"                 
                 $present = (Test-Path -Path "$($this.DownloadPath)\Community\Scripts\ModelAliasExit.vbs")
                 Write-Verbose "   $present"
                 if($Present){}Else{return $false}   
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

        Write-Verbose "Test completed!"
        return $present
    }

    [cMDTPreReqs] Get()
    {
        return $this
    }

    [bool] TestDownloadPath()
    {
        $present = $false

        if (Test-Path -Path $this.DownloadPath -ErrorAction Ignore)
        {
            $present = $true
        }        

        return $present
    }

    [bool] VerifyFiles()
    {

        [bool]$match = $false

        if (Get-ChildItem -Path $this.DownloadPath -Recurse)
        {
            #ForEach File, test...
            $match = $true
        }
        
        return $match
    }

    [void] WebClientDownload($Source,$Target)
    {
        $WebClient = New-Object System.Net.WebClient
        Write-Verbose "      Downloading file $($Source)"
        Write-Verbose "      Downloading to $($Target)"
        $WebClient.DownloadFile($Source, $Target)
    }

    [void] ExtractFile($Source,$Target)
    {
        Write-Verbose "      Extracting file to $($Target)"
        Expand-Archive $Source -DestinationPath $Target -Force
    }

    [void] CleanTempDirectory($Object)
    {

        Remove-Item -Path $Object -Force -Recurse -Verbose:$False
    }

    [void] RemoveDirectory($referencefile = "")
    {
        Remove-Item -Path $this.DownloadPath -Force -Verbose     
    }

    [void] RemoveReferenceFile($File)
    {
        Remove-Item -Path $File -Force -Verbose:$False
    }
}
