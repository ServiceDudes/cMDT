Function Invoke-CreatePath
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
        [string]$PSDrivePath
    )

    [bool]$present = $false

    if (($PSDrivePath) -and ($PSDriveName))
    {

        Import-MicrosoftDeploymentToolkitModule

        New-PSDrive -Name $PSDriveName -PSProvider "MDTProvider" -Root $PSDrivePath -Verbose:$false

        $Script:Directory = $($($Path.Split("\"))[0])
        For ($i=1; $i -le $($Path.Split("\").Count-1); $i++) {
            $Script:Directory += "\$($($Path.Split("\"))[$i])"
            If(-not(Invoke-TestPath -Path $Script:Directory -PSDriveName $PSDriveName -PSDrivePath $PSDrivePath -Verbose))
            {
                Try
                {
                    New-Item -ItemType Directory -Path $Script:Directory  -Verbose
                    #Invoke-Logger -Message "Successfully created: $Directory" -Category "DIRECTORY" -Type "CREATE"
                    $present = $true

                }
                Catch
                {
                    #Invoke-Logger -Severity "E" -Category "DIRECTORY" -Type "CREATE" -Error $Error[0]
                }
            }
        }
             
    }
    else
    {

        $Script:Directory = $($($Path.Split("\"))[0])
        For ($i=1; $i -le $($Path.Split("\").Count-1); $i++) {
            $Script:Directory += "\$($($Path.Split("\"))[$i])"
            If(-not(Invoke-TestPath -Path $Script:Directory -Verbose))
            {
                Try
                {
                    New-Item -ItemType Directory -Path $Script:Directory -Verbose
                    #Invoke-Logger -Message "Successfully created: $Directory" -Category "DIRECTORY" -Type "CREATE"
                    $present = $true
                }
                Catch
                {
                    #Invoke-Logger -Severity "E" -Category "DIRECTORY" -Type "CREATE" -Error $Error[0]
                }
            }
        }
    }

    return $present
}
