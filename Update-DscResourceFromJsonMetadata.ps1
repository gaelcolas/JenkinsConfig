$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$ModuleName = Split-Path -Path $pwd -Leaf
$DscResourceDefinition = Get-Content -Raw "$here\$ModuleName\DSCResources\DSCResourcesDefinitions.json" | ConvertFrom-Json


foreach ($Resource in $DscResourceDefinition)
{
    $DscProperties = @()
    $ResourceName = $Resource.psobject.Properties.Name
    foreach ($DscProperty in $Resource.($ResourceName)) {
        $resourceParams = @{}
        $DscProperty.psobject.properties | % { $resourceParams[$_.Name] = $_.value }
        $DscProperties += New-xDscResourceProperty @resourceParams
    }
    
    if (Test-Path "$here\JenkinsConfig\DscResources\$ResourceName") {
        $DscResourceParams = @{
             Property     = $DscProperties 
             Path         = "$here\JenkinsConfig\DscResources\$ResourceName"
             FriendlyName = $ResourceName 
        }
        Update-xDscResource @DscResourceParams -Force
    }
    else {
        $DscResourceParams = @{
             Name         = $ResourceName 
             Property     = $DscProperties 
             Path         = "$here\JenkinsConfig\"
             FriendlyName = $ResourceName 
        }
        New-xDscResource @DscResourceParams
    }
}
