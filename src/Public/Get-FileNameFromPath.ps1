Function Get-FileNameFromPath
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

    [string]$fileName = $Path.Split($Separator)[-1]

    return $fileName

}
