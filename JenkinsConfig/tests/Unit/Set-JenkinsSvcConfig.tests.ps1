$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

function Get-JavaCommandFromJavaCommandObject {Param($JavaCommandObject) }

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
$sampleConfigObject = [PSCustomObject]@{
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


Describe 'Set-JenkinsSvcConfig' {
Mock Get-JavaCommandFromJavaCommandObject -MockWith { $argumentsString } -Verifiable
  Context 'General context'   {
  
  $testXML = "$TestDrive\Jenkins.xml"
    It 'runs without errors' {
        { Set-JenkinsSvcConfig -ConfigurationObject $sampleConfigObject -JenkinsXMLPath $testXML } | Should Not Throw
    }

    It 'Creates the XML file' {
        Test-Path -Path $testXML | Should be $True
    }

    $xml = [xml]::new()
    It 'is a valid XML' {   
        { $xml.Load($testXML) } | Should not throw
    }

    It 'Has the required properties/values' {
        $xml.Service | Should not beNullOrEmpty
        $xml.Service.id | Should be 'Jenkins'
        $xml.Service.name | Should be 'JenkinsName'
        $xml.Service.description | Should be 'Jenkins service description'
        $xml.Service.env.name | Should be 'envName'
        $xml.Service.executable | Should be 'java'
        $xml.Service.arguments | Should be $argumentsString
        $xml.Service.logmode | Should be 'rotate'
        $xml.Service.onfailure.action | Should be 'restart'
    }

    It 'Called Get-JavaCommandFromJavaCommandObject' {
        Assert-VerifiableMocks
    }
  }
}
