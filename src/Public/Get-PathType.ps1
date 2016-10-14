Function Get-Separator
{
    [CmdletBinding()]
    [OutputType([String])]
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
