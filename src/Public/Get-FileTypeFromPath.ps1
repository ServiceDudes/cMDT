Function Get-FileTypeFromPath
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Separator
    )

    [string]$fileType = ($Path.Split($Separator)[-1]).Split(".")[-1]

    return $fileType

}
