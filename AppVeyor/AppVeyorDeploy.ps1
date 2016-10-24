#---------------------------------# 
# Header                          # 
#---------------------------------#

Write-Host 'Running AppVeyor deploy script' -ForegroundColor Yellow

#---------------------------------# 
# Update module manifest          # 
#---------------------------------# 

$ModuleManifestPath = Join-Path -path "$pwd" -ChildPath ("$env:ModuleName"+'.psd1')
$ModuleManifest     = Get-Content $ModuleManifestPath -Raw

Write-Host "Updating module manifest to version: $env:APPVEYOR_BUILD_VERSION"
[regex]::replace($ModuleManifest,'(ModuleVersion = )(.*)',"`$1'$env:APPVEYOR_BUILD_VERSION'") | Out-File -LiteralPath $ModuleManifestPath

#---------------------------------# 
# Creating NuGet Artifact         # 
#---------------------------------# 

# Creating project artifact
$stagingDirectory = "C:\Projects\cMDT\Builds"
$zipFilePath      = "C:\Projects\cMDT\cMDT.zip"
Add-Type -assemblyname System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($stagingDirectory, $zipFilePath)


# Creating NuGet package artifact
$NuGetParams = @{
    packageName        = $env:APPVEYOR_PROJECT_NAME
    version            = $env:APPVEYOR_BUILD_VERSION
    author             = "ServiceDudes"
    owners             = "ServiceDudes"
    licenseUrl         = ""
    projectUrl         = ""
    packageDescription = $env:APPVEYOR_PROJECT_NAME
    tags               = ""
    destinationPath    = "."
}
New-Nuspec @NuGetParams
nuget pack ".\$($env:APPVEYOR_PROJECT_NAME).nuspec" -outputdirectory "C:\Projects\cMDT"
$nuGetPackageName = $env:APPVEYOR_PROJECT_NAME + "." + $env:APPVEYOR_BUILD_VERSION + ".nupkg"
$nuGetPackagePath = (Get-ChildItem $nuGetPackageName).FullName

@(
    # You can add other artifacts here
    $zipFilePath,
    $nuGetPackagePath
) | % {
    Write-Host "Pushing package $_ as Appveyor artifact"
    Push-AppveyorArtifact $_
}

#---------------------------------# 
# Publish to PS Gallery           # 
#---------------------------------# 

if ($env:APPVEYOR_REPO_BRANCH -match 'master')
{
    Write-Host "Publishing module to Powershell Gallery: "
    #Publish-Module -Name $env:ModuleName -NuGetApiKey $env:nugetKey        
}

Write-Host 'Done!' -ForegroundColor Green