Configuration  JenkinsSvcJavaOption {
    Import-DscResource -ModuleName JenkinsConfig
    Import-DscResource -ModuleName PackageManagementProviderResource
    Node localhost {
        PackageManagement vscode {
            Ensure = 'Present'
            Name = 'visualstudiocode'
            ProviderName = 'Chocolatey'
        }

        PackageManagement Jenkins {
            Ensure = 'Present'
            Name = 'jenkins'
            ProviderName = 'Chocolatey'
        }
        
        JenkinsSvcJavaOption runSetupWizardFalse {
            ResolutionMode = 'UpdateAndAdd'
            Tokens = '-Djenkins.install.runSetupWizard=false'
            RunName = 'Initial Setup'
            ServiceName = 'Jenkins'
            RestartService = $True
        }

        JenkinsSvcJarArgument HttpPort {
            ResolutionMode = 'UpdateAndAdd'
            Tokens = '--httpPort=8080'
            RunName = 'Initial port setup'
            ServiceName = 'Jenkins'
            RestartService = $true
        }
    }
}