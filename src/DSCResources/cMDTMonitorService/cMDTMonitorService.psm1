enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTMonitorService
{

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [ValidateSet('Yes')]
    [DscProperty(Key)] 
    [ValidateNotNullorEmpty()]
    [String] $IsSingleInstance = 'Yes'

    [DscProperty(Mandatory)]
    [string]$PSDriveName

    [DscProperty(Mandatory)]
    [string]$PSDrivePath

    [DscProperty(Mandatory)]
    [string]$MonitorHost

    [void] Set()
    {

        # Check if monitor service is enabled
        $present = $this.MDTMonitorServiceIsEnabled()
        
        # Should monitor service be enabled
        if ($this.Ensure -eq [ensure]::Present -and $present -eq $false)
        {

            # Enable monitor service
            $this.EnableMDTMonitorService()            
        }
        elseif ($this.Ensure -eq [ensure]::Absent -and $present -eq $true)
        {

            # Disable monitor service
            $this.DisableMDTMonitorService()
        }
        
    }

    [bool] Test()
    {
        
        # Check if monitor service is enabled
        $present = $this.MDTMonitorServiceIsEnabled()

        # Return boolean from test method
        if ($this.Ensure -eq [ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTMonitorService] Get()
    {
        return $this
    }

    [bool] MDTMonitorServiceIsEnabled()
    {
    
        # Check if monitor service is started  
        try
        {
            $service = Get-Service MDT_Monitor -ErrorAction Stop
            if ($service.Status -ne 'Running')
            {
                return $false
            }
        }
        catch 
        {
            return $false
        }

        # Check if firewall ports for monitoring is opened
        if (!(Test-NetConnection -Port 9800 -ComputerName localhost -InformationLevel Quiet))
        {
            return $false
        }
        if (!(Test-NetConnection -Port 9801 -ComputerName localhost -InformationLevel Quiet))
        {
            return $false
        }

        try
        {

            # Get firewall rule for monitor service
            $rule = Get-NetFirewallRule -DisplayName 'MDT Monitor' -ErrorAction Stop

            # Get ports from firewall rule
            $ports = $rule | Get-NetFirewallPortFilter

            # Check if ports are defined in rule
            if (!($ports.LocalPort.Contains('9800') -and $ports.LocalPort.Contains('9801')))
            {
                return $false
            }
        }
        catch 
        {
            return $false
        }
        return $true
    }

    [void] EnableMDTMonitorService()
    {

        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        # Create PSDrive
        New-PSDrive -Name $this.PSDriveName -PSProvider "MDTProvider" -Root $this.PSDrivePath -Verbose:$false

        # Enable monitor service
        Enable-MDTMonitorService -EventPort 9800 -DataPort 9801

        # Define host and ports
        Set-ItemProperty "$($this.PSDriveName):\" -Name MonitorHost -Value $this.MonitorHost
        Set-ItemProperty "$($this.PSDriveName):\" -Name MonitorEventPort -Value "9800"
        Set-ItemProperty "$($this.PSDriveName):\" -Name MonitorDataPort -Value "9801"
       
    }

    [void] DisableMDTMonitorService()
    {

        # Import MicrosoftDeploymentToolkitModule module
        Import-MicrosoftDeploymentToolkitModule

        # Enable monitor service
        Disable-MDTMonitorService

        # Remove host and ports
        Set-ItemProperty "$($this.PSDriveName):\" -Name MonitorHost -Value ""
        Set-ItemProperty "$($this.PSDriveName):\" -Name MonitorEventPort -Value ""
        Set-ItemProperty "$($this.PSDriveName):\" -Name MonitorDataPort -Value ""
    }
    
}
