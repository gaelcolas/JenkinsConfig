$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

function Get-JenkinsXml {[cmdletBinding()]param($JenkinsXMLPath)}
function Get-JenkinsJavaArguments {param($JenkinsXMLPath) }

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


Describe 'Get-JenkinsSvcConfig' {

Mock -CommandName Get-JenkinsXml -MockWith {$SampleJenkinsXml}
Mock -CommandName Get-JenkinsJavaArguments { $SampleJenkinsXml.service.arguments }

  Context 'General context'   {

    It 'runs without errors' {
        { Get-JenkinsSvcConfig } | Should Not Throw
    }
    
    It 'Returns the expected object based'     {
      $result = Get-JenkinsSvcConfig
      Compare-Object -ReferenceObject $SampleJenkinsXml -DifferenceObject $result -Property service | Should BeNullOrEmpty 
      Compare-Object -ReferenceObject $SampleJenkinsXml.Service -DifferenceObject $result.service -Property id,name,description,env,executable,arguments,logmode,onfailure | Should BeNullOrEmpty  
    }
  }
}
