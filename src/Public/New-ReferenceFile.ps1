Function New-ReferenceFile
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

    Begin
    {
    }
    Process
    {
        if (($PSDrivePath) -and ($PSDriveName))
        {

            Import-MicrosoftDeploymentToolkitModule            New-PSDrive -Name $PSDriveName -PSProvider "MDTProvider" -Root $PSDrivePath -Verbose:$false | `            New-Item -Type File -Path $Path -Force -Verbose:$False     
        }
        else
        {

            New-Item -Type File -Path $Path -Force -Verbose:$False  
        }
    }
    End
    {
    }
}
