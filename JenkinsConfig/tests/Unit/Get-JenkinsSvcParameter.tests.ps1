$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder
#region functions for Mock
function Get-JenkinsHomeFromSvcName { Param($ServiceId) }
function Get-jenkinsSvcConfig {[CmdletBinding()]param($JenkinsXMLPath)} #-JenkinsXMLPath $JenkinsXMLPath -ErrorAction Sto
function Get-ArgumentFromToken {param([string[]]$ArgumentToken, [io.fileinfo]$ArgumentsDefinitionFile)}
#endregion

$Params = @{
        JavaOptionOrJarArgument = 'JavaOption'
        JenkinsXMLPath = "$here/Resources/NewJenkins.xml"
      }
$JenkinsArgObject = [PSCustomObject]@{PSTypeName='Jenkins.KeyValuePair';property='httpPort';value='443'}
#region Creating mocked Objects
$argumentsString = '-Xrs -Xmx256m -Dhudson.lifecycle=hudson.lifecycle.WindowsServiceLifecycle -Djenkins.install.runSetupWizard=false -Jar "%BASE%\jenkins.war" --httpPort=8080 --webroot="%BASE%\war"'
$ArgumentsTokens= $argumentsString -split '\s'
$SampleArgumentObject = [PSCustomObject]@{
    PSTypeName   = 'Java.CommandObject'
    'Executable' = ''
    'Options'    = $ArgumentsTokens[0..3]
    'isJar'      = $true
    'ClassOrJar' = $ArgumentsTokens[4]
    'Arguments'  = $ArgumentsTokens[5,6]
}
$SampleJenkinsXml = [PSCustomObject]@{
                        PSTypeName = 'Jenkins.configuration'
                        Service = ([PSCustomObject]@{
                            id = 'Jenkins'
                            name = 'JenkinsName'
                            description = 'Jenkins service description'
                            env = [PSCustomObject]@{name='envName';value='envValue'}
                            executable='java'
                            arguments=$SampleArgumentObject
                            logmode = 'rotate'
                            onfailure= [PSCustomObject]@{action='restart'}
                        })
                    }
#endregion

Describe 'Get-JenkinsJavaArgument' {
#TODO: Handle the test when JavaOptionOrJarArgument = JarArgument
Mock Get-JenkinsHomeFromSvcName -MockWith {'C:\File\Path.xml'}
Mock Get-JenkinsSvcConfig -MockWith { $SampleJenkinsXml } -Verifiable
Mock Get-ArgumentFromToken -MockWith { $JenkinsArgObject } -Verifiable

  Context 'General functional tests'   {

    It 'runs without errors and calls functions' {
        $cmdResult = Get-JenkinsSvcParameter @Params  
        Compare-Object -ReferenceObject $JenkinsArgObject -DifferenceObject $cmdResult -Property property,value| Should beNullOrEmpty
        Assert-VerifiableMocks
    }
  }
}
