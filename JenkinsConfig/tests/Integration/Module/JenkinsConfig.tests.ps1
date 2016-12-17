
Describe 'Module JenkinsConfig Integration test' -Tags 'Integration' {

    Context 'Independant functions' {
        It 'Loads the module' {
            { Import-module -force JenkinsConfig} | should not throw
        }

        It 'Get-JenkinsHomeFromSvcName should not error' {
            { Get-JenkinsHomeFromSvcName } | Should not Throw
            { Get-JenkinsHomeFromSvcName -ServiceId $null } | Should not Throw
        }

        It 'Get-JenkinsSvcConfig does not error' {
            { Get-JenkinsSvcConfig } | Should not Throw
        }

        It 'Get-JenkinsSvcParameter does not error' {
            { Get-JenkinsSvcParameter -JavaOptionOrJarArgument JarArgument} | Should not Throw
            { Get-JenkinsSvcParameter -JavaOptionOrJarArgument JarArgument} | Should not Throw
        }

        It 'Set-JenkinsSvcParameter does not error' {
            $JenkinsHome = Get-JenkinsHomeFromSvcName
            $JenkinsXML = Join-Path -Path $JenkinsHome -ChildPath Jenkins.xml
            { Get-JenkinsSvcConfig -JenkinsXMLPath $JenkinsXML | Set-JenkinsSvcConfig -JenkinsXMLPath $JenkinsXML } | Should not throw
        }

        It 'Gets the JenkinsHome from a base install' {
            $JenkinsHome = Get-JenkinsHomeFromSvcName -ServiceId 'Jenkins'
            $JenkinsHome | Should be 'C:\Program Files (x86)\Jenkins'
        }

        It 'Retrieves the Service configuration object' {
            $SvcConfig = Get-JenkinsSvcConfig -JenkinsXMLPath 'C:\Program Files (x86)\Jenkins\Jenkins.xml'
            $SvcConfig | Should not beNullOrEmpty
        }
    }
}