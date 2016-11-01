Function Write-Log
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        $Message
    )
    [String]$LogFile = "$($PSScriptRoot)\$(Get-Date -Format "yyyy-MM-dd")_cMDT.log"
    Out-File -FilePath $LogFile -InputObject $Message -Encoding utf8 -Append -NoClobber
    #Write-Verbose $Message
}