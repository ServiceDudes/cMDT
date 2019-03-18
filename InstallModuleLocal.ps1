$DebugPreference = "Continue"
$VerbosePreference = "Continue"

function Main {
    Write-Verbose "Copy cMDT to WindowsPowerShell modules folder"
    try {
        $cMDTPath = "$Env:ProgramFiles\WindowsPowerShell\Modules\cMDT"
        if (Test-Path $cMDTPath) {
            Write-Verbose "Removing $cMDTPath"
            Remove-Item -Path $cMDTPath -Recurse -Force
        }

        Write-Verbose "Copying .\Builds\cMDT to $cMDTPath"
        Copy-Item .\Builds\cMDT -Destination $cMDTPath -Recurse

        Write-Verbose "...Done!"
    }
    catch {
        throw "Error: $($Error[0].Exception)"
    }
}

Main
