Function Get-Separator
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path
    )

    [string]$separator = ""
    If ($Path -like "*/*")
    { $separator = "/" }
    Else
    { $separator = "\" }

    return $separator

}
