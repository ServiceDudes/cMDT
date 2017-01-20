#---------------------------------# 
# Header                          # 
#---------------------------------# 
Write-Host 'Running AppVeyor test script' -ForegroundColor Yellow
Write-Host "Current working directory: $pwd"

#---------------------------------# 
# Run Pester Tests                # 
#---------------------------------# 
$resultsFile = '.\TestsResults.xml'
$testFiles   = Get-ChildItem "$pwd\tests" | Where-Object {$_.FullName -match 'Tests.ps1$'} | Select-Object -ExpandProperty FullName
$results     = Invoke-Pester -Script $testFiles -OutputFormat NUnitXml -OutputFile $resultsFile -PassThru

Write-Host 'Uploading results'
try {
  Write-Host "About to upload file: $(Resolve-Path $resultsFile)"
  (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $resultsFile))
  Write-Host 'Uploading complete' -ForegroundColor Green
} catch {
  throw "Upload failed."
  Write-Host 'Uploading failed!'  -ForegroundColor Red
}

#---------------------------------# 
# Validate                        # 
#---------------------------------# 
if (($results.FailedCount -gt 0) -or ($results.PassedCount -eq 0) -or ($null -eq $results)) { 
  throw "$($results.FailedCount) tests failed."
} else {
  Write-Host 'All tests passed' -ForegroundColor Green
}