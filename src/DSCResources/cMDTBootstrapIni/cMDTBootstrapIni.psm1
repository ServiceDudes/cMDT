enum Ensure
{
    Absent
    Present
}

[DscResource()]
class cMDTBootstrapIni
{

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(Key)]
    [string]$Path

    [DscProperty()]
    [string]$Content

    [void] Set()
    {

        # Check if defined as present
        if ($this.Ensure -eq [Ensure]::Present)
        {
            # If set to present set content according to contract
            $this.SetContent()
        }
        else
        {
            # If set to absent revert to default content
            $this.SetDefaultContent()
        }
    }

    [bool] Test()
    {
        # Call function to test file content according to contract
        $present = $this.TestFileContent()
        
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else
        {
            return -not $present
        }
    }

    [cMDTBootstrapIni] Get()
    {
        return $this
    }

    [bool] TestFileContent()
    {
        $present = $false

        # Import existing file content
        $existingConfiguration = Get-Content -Path $this.Path -Raw #-Encoding UTF8

        $contract = $this.Content.Replace("`n","`r`n")
        $contract = $contract.Replace("DeployRoot=\\CLIENT","DeployRoot=\\$($env:COMPUTERNAME)")
        $contract = $contract.Replace("UserDomain=CLIENT","UserDomain=$($env:COMPUTERNAME)")

        # Match against content from contract
        if ($existingConfiguration -eq $contract)
        {
            $present = $true   
        }

        # Return state
        return $present
    }

    [void] SetContent()
    {
        $contract = $this.Content.Replace("`n","`r`n")
        $contract = $contract.Replace("DeployRoot=\\CLIENT","DeployRoot=\\$($env:COMPUTERNAME)")
        $contract = $contract.Replace("UserDomain=CLIENT","UserDomain=$($env:COMPUTERNAME)")

        # Set new file content
        Set-Content -Path $this.Path -Value $contract -NoNewline -Force #-Encoding UTF8 
    }
    
    [void] SetDefaultContent()
    {
        # Set default content
        $defaultContent = @"
[Settings]
Priority=Default

[Default]

"@
        Set-Content -Path $this.Path -Value $defaultContent -NoNewline -Force #-Encoding UTF8 
    }
}
