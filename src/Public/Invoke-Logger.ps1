Function Invoke-Logger
{
    param(
        [String]$Severity,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [String]$Category,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [String]$Type,

        $Message,

        $Error
    )

    Switch ($Severity) 
    { 
        "I"     { $Severity = "INFO" }
        "D"     { $Severity = "DEBUG" }
        "W"     { $Severity = "WARNING" }
        "E"     { $Severity = "ERROR"}
        default { $Severity = "INFO" }
    }

    $date = [datetime]::UtcNow
    
    For ($x=$Severity.Length; $x -le 6; $x++)  { $Severity = $Severity+" " }
    For ($x=$Category.Length; $x -le 7; $x++) { $Category = $Category+" " }
    For ($x=$Type.Length;     $x -le 7; $x++) { $Type     = $Type+" " }

    If ($Error)
    {
        ForEach ($Line in $Message)
        {
            Write-Log -Message "[$(Get-Date $date -UFormat '%Y-%m-%dT%T%Z')] [$($Severity)] [$($Category)] [$($Type)] [$($Line)]"
        }
        If ($Error.Exception.Message) { Write-Log -Message "[$(Get-Date $date -UFormat '%Y-%m-%dT%T%Z')] [$($Severity)] [$($Category)] [$($Type)] [$($Error.Exception.Message)]" }
        If ($Error.Exception.Innerexception) { Write-Log -Message "[$(Get-Date $date -UFormat '%Y-%m-%dT%T%Z')] [$($Severity)] [$($Category)] [$($Type)] [$($Error.Exception.Innerexception)]" }
        If ($Error.InvocationInfo.PositionMessage) {
            ForEach ($Line in $Error.InvocationInfo.PositionMessage.Split("`n"))
            {
                Write-Log -Message "[$(Get-Date $date -UFormat '%Y-%m-%dT%T%Z')] [$($Severity)] [$($Category)] [$($Type)] [$($Line)]"
            }
        }
    }
    Else
    {
        If ($Message)
        {
            If (($Message.GetType()).Name -eq "Hashtable")
            {
                Get-RecursiveProperties -Value $Message
            }
            Else
            {
                ForEach ($Line in $Message)
                {
                    Write-Log -Message "[$(Get-Date $date -UFormat '%Y-%m-%dT%T%Z')] [$($Severity)] [$($Category)] [$($Type)] [$($Line)]"
                }
            }
        }
    }

}
