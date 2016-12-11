Configuration MyJenkins {
    Import-DscResource -ModuleName Jenkins
    Import-DscResource -ModuleName PackageManagementProviderResource
    Node localhost {
        PackageManagement vscode {
            Ensure = 'Present'
            Name = 'visualstudiocode'
            ProviderName = 'Chocolatey'
        }
        
        Jenkins JenkinsMaster {
            Ensure = 'Present'
            Port = 8080
            #InstallationPath = 'C:\Jenkins' #not supported by the PackageManagement DSC resource (actually, not supported by Install-package -providerName Chocolatey)
        }
    }
}