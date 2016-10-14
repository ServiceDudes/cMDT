Function Invoke-RemovePath
{
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullorEmpty()]
        [string]$Path,

        [Parameter()]
        [string]$PSDriveName,

        [Parameter()]
        [string]$PSDrivePath,

        [Parameter()]
        [int32]$Levels,

        [Parameter()]
        [switch]$Recurse
    )

    [bool]$Verbosity
    If($PSBoundParameters.Verbose)
    { $Verbosity = $True }
    Else
    { $Verbosity = $False }

    if (($PSDrivePath) -and ($PSDriveName))
    {

        Import-MicrosoftDeploymentToolkitModule

        New-PSDrive -Name $PSDriveName -PSProvider "MDTProvider" -Root $PSDrivePath -Verbose:$False        Try
        {
            Remove-Item -Path $Path -Force -Verbose:$Verbosity
            #Invoke-Logger -Message "Successfully removed: $Path" -Category "DIRECTORY" -Type "REMOVE"
        }
        Catch
        {
            #Invoke-Logger -Severity "E" -Category "DIRECTORY" -Type "CREATE" -Error $Error[0]
        }
        If ($Recurse)
        {
            $Script:Dir = $Path
            For ($i=$($Path.Split("\").Count-1); $i -ge $Levels; $i--) {
                $Script:Dir = $Script:Dir.Replace("\$($($Path.Split("\"))[$i])","")
                If(-not(Invoke-TestPath -Path "$Dir\*" -PSDriveName $PSDriveName -PSDrivePath $PSDrivePath -Verbose))
                {
                    Try
                    {
                        Remove-Item -Path $Dir -Force -Verbose:$Verbosity
                        #Invoke-Logger -Message "Successfully removed: $Dir" -Category "DIRECTORY" -Type "REMOVE"
                    }
                    Catch
                    {
                        #Invoke-Logger -Severity "E" -Category "DIRECTORY" -Type "CREATE" -Error $Error[0]
                    }

                }
            }
        }

    }
    else
    {

        Try
        {
            Remove-Item -Path $Path -Force -Verbose:$Verbosity
            #Invoke-Logger -Message "Successfully removed: $Path" -Category "DIRECTORY" -Type "REMOVE"
        }
        Catch
        {
            #Invoke-Logger -Severity "E" -Category "DIRECTORY" -Type "CREATE" -Error $Error[0]
        }

        If ($Recurse)
        {
            $Script:Dir = $Path
            For ($i=$($Path.Split("\").Count-1); $i -ge 4; $i--) {
                $Script:Dir = $Script:Dir.Replace("\$($($Path.Split("\"))[$i])","")
                If(-not(Invoke-TestPath -Path "$Dir\*" -Verbose))
                {
                    Try
                    {
                        Remove-Item -Path $Dir -Force -Verbose:$Verbosity
                        #Invoke-Logger -Message "Successfully removed: $Dir" -Category "DIRECTORY" -Type "REMOVE"
                    }
                    Catch
                    {
                        Invoke-Logger -Severity "E" -Category "DIRECTORY" -Type "CREATE" -Error $Error[0]
                    }
                }
            }
        }

    }
}
