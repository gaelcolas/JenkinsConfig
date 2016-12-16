$JavaOptionsTokens = (Get-JenkinsJavaArguments -JenkinsXMLPath C:\src\JenkinsConfig\JenkinsConfig\tests\Unit\Resources\jenkins.xml).options
$JavaOptions = Get-ArgumentsFromTokens -ArgumentsTokens $JavaOptionsTokens
if (!($JavaOptionsTokens -match '-Djenkins.install.runSetupWizard=true')) {
    if ($Option = $JavaOptions | ? {  })

}




$tokens = (Get-TokenizedCommand -InputObject '-Xrs -Xmx256m -Dhudson.lifecycle=hudson.lifecycle.WindowsServiceLifecycle -Djenkins.install.runSetupWizard=false -Jar "%BASE%\jenkins.war" --httpPort=8080 --webroot="%BASE%\war"')
$javaCommandObject = Get-JavaCommandObjectFromTokenizedCommand $tokens
$existingArguments = Get-ArgumentsFromTokens -ArgumentsTokens $javaCommandObject.Arguments -ArgumentsDefinitionFile .\JenkinsConfig\config\JenkinsArguments.definition.json
$newArg = Get-ArgumentsFromTokens -ArgumentsTokens '--httpPort=8443' -ArgumentsDefinitionFile .\JenkinsConfig\config\JenkinsArguments.definition.json
Merge-Arguments -UpdateSource $newArg -ExistingArguments $existingArguments -ResolutionBehavior UpdateAndAdd -ArgumentsDefinitionFile .\JenkinsConfig\config\JenkinsArguments.definition.json





$jenkinsSvcInstall = @{
    Ensure = 'Present' #'Absent'
    Port = 8080
    runSetupWizard   = $false
    InstallationPath = 'C:\Jenkins'
    AdminCredential  = $Admincred
    RunServiceAs     = $runAsCred
}


$JenkinsSvcJavaOption = @{
    Ensure = 'Present'
    Identifier = 'Basic Options'
    Tokens = @('-Xmx256m',
                '-Xrs',
                '-Dhudson.lifecycle=hudson.lifecycle.WindowsServiceLifecycle',
                '-Djenkins.install.runSetupWizard=false'
              )
    ResolutionMode = 'UpdateAndAdd' #'UpdateOnly','ExactAndFinal'
}

$JenkinsSvcJarArguments =  @{
    Ensure = 'Present'
    Identifier = 'Basic Arguments'
    Tokens = @('--httpport=8080','--webroot="%BASE%\war')
    ResolutionMode = 'ExactAndFinal'
    #ArgumentParserDefinitionFile = 'C:\test.json'
}

$JenkinsSvcJavaOption = @{
    Ensure = 'Absent'
    Identifier = ''
    Tokens = @('-Xmx256m')
    ResolutionMode = 'Delete','Error','SetDefaultValue'
    ArgumentParserDefinitionFile = 'C:\test.json'
}

$jenkinsPluginInstall = @{
    Ensure = 'Present' #'Absent'
    plugin_id = 'git'
    version = 'latest'
}

$adminCred = $runAsCred = Get-Credential


$JenkinsGitBash = @{
    Ensure = 'Present'
    Name = 'Jenkins'
    email = 'jenkins@yourorg.com'
    sshKey = ''
}

$JenkinsJobBuilderRunner = @{
    Credential = $adminCred
    JenkinsJobsRepo = 'jjb-repo@github.com'
}


