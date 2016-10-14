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

#<![LOG[Report state message 0x40000950 to MP]LOG]!><time="01:38:47.034-120" date="07-16-2016" component="SMS_Distribution_Point_Monitoring" context="" type="1" thread="12172" file="smsdpmon.cpp:889">
#<![LOG[Begin validation of Certificate [Thumbprint 5F1966C815ADC9B25E8D9979917E26B5396D9154] issued to 'winPE.dec.addlevel.net']LOG]!><time="19:25:40.755-120" date="05-27-2016" component="SMSPXE" context="" type="1" thread="7484" file="ccmcert.cpp:1715"> 

