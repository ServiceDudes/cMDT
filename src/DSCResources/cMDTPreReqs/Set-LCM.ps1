[DSCLocalConfigurationManager()]
Configuration LCM
{
    Node $env:COMPUTERNAME
    {
        Settings
        {
            AllowModuleOverwrite = $True
            ConfigurationMode    = 'ApplyAndMonitor'
            RefreshMode          = 'Push'
            Debugmode            = 'All'
            RebootNodeIfNeeded   = $True
        }
    }
}

LCM -OutputPath "C:\DSC"
Set-DscLocalConfigurationManager -Path "C:\DSC" -Verbose