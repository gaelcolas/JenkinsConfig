$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

$SampleJenkinsXml = [PSCustomObject]@{
                        Service = ([PSCustomObject]@{
                            arguments='-Xrs -Xmx256m -Dhudson.lifecycle=hudson.lifecycle.WindowsServiceLifecycle -Djenkins.install.runSetupWizard=false -Jar "%BASE%\jenkins.war" --httpPort=8080 --webroot="%BASE%\war"'
                        })
                    }
$arraySample = $SampleJenkinsXml.service.arguments -split ' '
$sampleOutput = [PSCustomObject]@{
    PSTypeName   = 'Java.CommandObject'
    'Executable' = ''
    'Options'    = $arraySample[0..3]
    'isJar'      = $true
    'ClassOrJar' = $arraySample[4]
    'Arguments'  = $arraySample[5,6]
}

function Get-JenkinsXml {param([io.fileinfo]$JenkinsXml)}
Mock -CommandName Get-JenkinsXml -MockWith { $SampleJenkinsXml}

function Get-JavaCommandObjectFromTokenizedCommand { param([string[]]$TokenizedCommand) }
Mock -CommandName Get-JavaCommandObjectFromTokenizedCommand -MockWith {
    Param($TokenizedCommand)
   
    [PSCustomObject]@{
    PSTypeName   = 'Java.CommandObject'
    'Executable' = ''
    'Options'    = $TokenizedCommand[0..3]
    'isJar'      = $true
    'ClassOrJar' = $TokenizedCommand[4]
    'Arguments'  = $TokenizedCommand[5,6]
    }
}

function Get-TokenizedCommand { param([PSCustomObject[]]$InputObject) }
Mock -CommandName Get-TokenizedCommand -MockWith { $sampleOutput }

Describe 'Get-JenkinsJavaArguments' {

  Context 'General context'   {

    It 'runs without errors' {
        { Get-JenkinsJavaArguments } | Should Not Throw
    }
    It 'does something' {
      
    }
    It 'does not return anything'     {
      Get-JenkinsJavaArguments | Should BeNullOrEmpty 
    }
  }
}
