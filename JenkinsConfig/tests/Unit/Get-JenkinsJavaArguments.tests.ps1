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
function Get-JavaCommandObjectFromTokenizedCommand { param([string[]]$TokenizedCommand) }
function Get-TokenizedCommand { param([PSCustomObject[]]$InputObject) }

Describe 'Get-JenkinsJavaArguments' {
    Mock -CommandName Get-JenkinsXml -MockWith { $SampleJenkinsXml}
    Mock -CommandName Get-TokenizedCommand -MockWith { $arraySample }

    Mock -CommandName Get-JavaCommandObjectFromTokenizedCommand -MockWith {
        Param($TokenizedCommand)
   
        write-output -InputObject ([PSCustomObject]@{
        PSTypeName   = 'Java.CommandObject'
        'Executable' = ''
        'Options'    = $TokenizedCommand[0..3]
        'isJar'      = $true
        'ClassOrJar' = $TokenizedCommand[4]
        'Arguments'  = $TokenizedCommand[5,6]
        })
    }


  Context 'General context'   {

    It 'runs without errors' {
        { Get-JenkinsJavaArguments -JenkinsXMLPath C:\this\is\mocked.ps1 } | Should Not Throw
    }

    It 'does not return anything'     {
      $result = Get-JenkinsJavaArguments
      Compare-Object -ReferenceObject $sampleOutput -DifferenceObject $result -Property Executable,Options,isJar,ClassOrJar,Arguments| Should BeNullOrEmpty
    }
  }
}
