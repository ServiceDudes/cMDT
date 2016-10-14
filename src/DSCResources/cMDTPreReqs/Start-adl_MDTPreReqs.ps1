Configuration adl_MDTPreReqs
{
    param (        
        [string[]]$ComputerName = "localhost"
    )
    
    Import-DscResource –ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName adl_MDTPreReqs

    Node $ComputerName
    {
        adl_MDTPreReqs MDTPreReqs {
            Ensure = "Present"            
            DownloadPath = "C:\Source"
        }
    }
}
adl_MDTPreReqs
Start-DscConfiguration adl_MDTPreReqs -Wait -Force -Verbose


#Trouble shooting DSC
Get-DscLocalConfigurationManager

$params = @{ 
    Namespace = 'root/Microsoft/Windows/DesiredStateConfiguration' 
    ClassName = 'MSFT_DSCLocalConfigurationManager' 
    MethodName = 'PerformRequiredConfigurationChecks' 
    Arguments = @{ 
        Flags = [uint32] 1 
    } 
} 
Invoke-CimMethod @params

Remove-DscConfigurationDocument -Stage Current -Force

Get-Command -Module xDscDiagnostics
Get-xDscOperation -Newest 2
Get-xDscOperation -Newest 1 | fl *
Get-xDscOperation -Newest 1 | Show-Object


Update-xDscEventLogStatus -Channel Analytic -Status Enabled
Update-xDscEventLogStatus -Channel Debug -Status Enabled
Trace-XDscOperation