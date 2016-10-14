﻿Function New-ReferenceFile
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path,
        [Parameter()]
        [string]$PSDriveName,
        [Parameter()]
        [string]$PSDrivePath
    )
    if (($PSDrivePath) -and ($PSDriveName))
    {

        Import-MicrosoftDeploymentToolkitModule
    }
    else
    {

        New-Item -Type File -Path $Path -Force -Verbose:$False  
    }
}