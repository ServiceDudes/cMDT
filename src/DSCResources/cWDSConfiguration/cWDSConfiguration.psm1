enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cWDSConfiguration
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [string]$RemoteInstallPath


    [void] Set()
    {

        if ($this.Ensure -eq [Ensure]::Present)
        {
            $this.InitializeServer()
        }
        else
        {
            $this.UninitializeServer()
        }
    }

    [bool] Test()
    {
        $present = $this.DoesRemoteInstallFolderExist()
        
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [bool] IsPartOfDomain()
    {
        return (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
    }

    [cWDSConfiguration] Get()
    {
        return $this
    }

    [bool] DoesRemoteInstallFolderExist()
    {
        return (Test-Path $this.RemoteInstallPath -ErrorAction Ignore)
    }

    [void] InitializeServer()
    {
        if ($this.IsPartOfDomain())
        {
            & WDSUTIL /Initialize-Server /RemInst:"$($this.RemoteInstallPath)" /Authorize
        }
        else
        {
            & WDSUTIL /Initialize-Server /RemInst:"$($this.RemoteInstallPath)" /Standalone
        }        
        & WDSUTIL /Set-Server /AnswerClients:All

    }
    
    [void] UninitializeServer()
    {
       & WDSUTIL /Uninitialize-Server
    }
    
}
