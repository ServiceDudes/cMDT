Function Get-FolderNameFromPath
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

    [string]$folderName = $Path.Replace("\$($Path.Split($Separator)[-1])","")

    return $folderName

}
