Function Invoke-WebDownload
{
    [CmdletBinding(SupportsShouldProcess = $false)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Source,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Target
    )


    Begin
    {
        [bool]$Verbosity
        If($PSBoundParameters.Verbose)
        { $Verbosity = $True }
        Else
        { $Verbosity = $False }
    }
    Process
    {
        If ($Source -like "*/*")
        {
            If (Get-Service BITS | Where-Object {$_.status -eq "running"})
            {

                If ($Verbosity) { Write-Verbose "Downloading file $($Source) via Background Intelligent Transfer Service" }
                Import-Module BitsTransfer -Verbose:$false
                Start-BitsTransfer -Source $Source -Destination $Target -Verbose:$Verbosity
                Remove-Module BitsTransfer -Verbose:$false
            }
            else
            {

                If ($Verbosity) { Write-Verbose "Downloading file $($Source) via System.Net.WebClient" }
                $WebClient = New-Object System.Net.WebClient
                $WebClient.DownloadFile($Source, $Target)
            }
        }
        Else
        {
            If (Get-Service BITS | Where-Object {$_.status -eq "running"})
            {
                If ($Verbosity) { Write-Verbose "Downloading file $($Source) via Background Intelligent Transfer Service" }
                Import-Module BitsTransfer -Verbose:$false
                Start-BitsTransfer -Source $Source -Destination $Target -Verbose:$Verbosity
            }
            Else
            {
                Copy-Item $Source -Destination $Target -Force -Verbose:$Verbosity
            }
        }
    }
    End
    {
    }
}
