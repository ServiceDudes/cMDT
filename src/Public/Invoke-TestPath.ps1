Function Invoke-TestPath
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path,

        [Parameter()]
        [string]$PSDriveName,

        [Parameter()]
        [string]$PSDrivePath
    )

    [bool]$present = $false

    if (($PSDrivePath) -and ($PSDriveName))
    {
        Import-MicrosoftDeploymentToolkitModule
        Try
        {
            If ($this.Debug) { Invoke-Logger -Message "New-PSDrive -Name $($PSDriveName) -PSProvider 'MDTProvider' -Root $($PSDrivePath) -Verbose:false -ErrorAction Stop" -Severity D -Category "TestPath" -Type TestPath }
            $PSDrive = New-PSDrive -Name $PSDriveName -PSProvider "MDTProvider" -Root $PSDrivePath -Verbose:$false -ErrorAction Stop

            If ($this.Debug) { Invoke-Logger -Message "Test-Path -Path $($Path) -ErrorAction Stop" -Severity D -Category "TestPath" -Type TestPath }
            $present = $PSDrive | Test-Path -Path $Path -ErrorAction Stop
        }
        Catch
        {
            If ($_[0].FullyQualifiedErrorId -eq "UpgradeRequired,Microsoft.PowerShell.Commands.NewPSDriveCommand")
            {
                If ($this.Debug) { Invoke-Logger -Message "UpgradeRequired,Microsoft.PowerShell.Commands.NewPSDriveCommand" -Severity E -Category "TestPath" -Type TestPath }
                Try
                {
                    If ($this.Debug) { Invoke-Logger -Message "New-PSDrive -Name $($PSDriveName) -PSProvider 'MDTProvider' -Root $($PSDrivePath) -Description 'MDT Deployment Share' -Force -Verbose | add-MDTPersistentDrive -Verbose" -Severity D -Category "TestPath" -Type TestPath }
                    New-PSDrive -Name $PSDriveName -PSProvider "MDTProvider" -Root $PSDrivePath -Description "MDT Deployment Share" -Force -Verbose | add-MDTPersistentDrive -Verbose
                }
                catch
                {
                    If ($this.Debug) { Invoke-Logger -Message $_ -Severity E -Category "TestPath" -Type TestPath }
                }
            }
            else
            {
                If ($this.Debug) { Invoke-Logger -Message $_ -Severity E -Category "TestPath" -Type TestPath }
            }
        }
    }
    Else
    {
        If (Test-Path -Path $Path -ErrorAction Ignore)
        {
            $present = $true
        }
    }

    return $present
}
