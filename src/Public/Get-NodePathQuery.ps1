Function Get-NodePathQuery {
    [OutputType([string])]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$Name
    )
    
    $query = "sequence"
    
    foreach ($group in $Path.Split("\")) {
        $query += "/group[@name='$group']"
    }
    
    if ($Name) {
        $query += "/step[@name='$Name']"
    }
    
    return $query
}
