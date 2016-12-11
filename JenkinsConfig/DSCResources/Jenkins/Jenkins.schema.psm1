Configuration JenkinsConfig
{
    param (
        # Port where Jenkins should listen to
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [int] $Port = 8080,

        [Parameter(Mandatory)]
        [ValidateSet('Absent','Present')]
        [String]$Ensure,

        [Parameter(Mandatory = $false)]
        [hashtable[]]$plugins = @(
            @{plugin_id = 'workflow-aggregator'; version = 'latest'}, 
            @{plugin_id = 'ant'},
            @{plugin_id = 'bouncycastle-api'},
            @{plugin_id = 'branch-api'},
            @{plugin_id = 'build-timeout'},
            @{plugin_id = 'credentials-binding'},
            @{plugin_id = 'credentials'},
            @{plugin_id = 'display-url-api'},
            @{plugin_id = 'durable-task'},
            @{plugin_id = 'email-ext'},
            @{plugin_id = 'external-monitor-job'},
            @{plugin_id = 'cloudbees-folder'},
            @{plugin_id = 'git-client'},
            @{plugin_id = 'git'},
            @{plugin_id = 'git-server'},
            @{plugin_id = 'github-api'},
            @{plugin_id = 'github-branch-source'},
            @{plugin_id = 'github-organization-folder'},
            @{plugin_id = 'github'},
            @{plugin_id = 'gradle'},
            @{plugin_id = 'icon-shim'},
            @{plugin_id = 'ace-editor'},
            @{plugin_id = 'handlebars'},
            @{plugin_id = 'jquery-detached'},
            @{plugin_id = 'momentjs'},
            @{plugin_id = 'junit'},
            @{plugin_id = 'ldap'},
            @{plugin_id = 'mailer'},
            @{plugin_id = 'mapdb-api'},
            @{plugin_id = 'matrix-auth'},
            @{plugin_id = 'matrix-project'},
            @{plugin_id = 'antisamy-markup-formatter'},
            @{plugin_id = 'pam-auth'},
            @{plugin_id = 'pipeline-graph-analysis'},
            @{plugin_id = 'workflow-api'},
            @{plugin_id = 'workflow-basic-steps'},
            @{plugin_id = 'pipeline-build-step'},
            @{plugin_id = 'workflow-cps'},
            @{plugin_id = 'pipeline-input-step'},
            @{plugin_id = 'workflow-job'},
            @{plugin_id = 'pipeline-milestone-step'},
            @{plugin_id = 'workflow-multibranch'},
            @{plugin_id = 'workflow-durable-task-step'},
            #@{plugin_id = 'pipeline-stage-view'}, #Not working, correct link: http://archives.jenkins-ci.org/plugins/pipeline-stage-view/latest/
            @{plugin_id = 'workflow-scm-step'},
            @{plugin_id = 'workflow-cps-global-lib'},
            @{plugin_id = 'pipeline-stage-step'},
            @{plugin_id = 'workflow-step-api'},
            @{plugin_id = 'workflow-support'},
            @{plugin_id = 'plain-credentials'},
            @{plugin_id = 'resource-disposer'},
            @{plugin_id = 'scm-api'},
            @{plugin_id = 'script-security'},
            @{plugin_id = 'ssh-credentials'},
            @{plugin_id = 'ssh-slaves'},
            @{plugin_id = 'structs'},
            @{plugin_id = 'subversion'},
            @{plugin_id = 'timestamper'},
            @{plugin_id = 'token-macro'},
            @{plugin_id = 'windows-slaves'},
            @{plugin_id = 'ws-cleanup'}
        ),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$InstallationPath = "C:\Program Files (x86)\Jenkins"
        
    )


    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName PackageManagementProviderResource

        PackageManagement Jenkins {
            Ensure = 'Present'
            Name = 'Jenkins'
            ProviderName = 'Chocolatey'
            #AdditionalParameters = @{AdditionalArguments = "JENKINSDIR=`"$InstallationPath`""}
        }
        
        PackageManagement Git {
            Ensure = 'Present'
            Name = 'git'
            ProviderName = 'Chocolatey'
        }

        # Set the Jenkins Port
        Script SetJenkinsPort
        {
            SetScript = {
                Write-Verbose -Verbose "Setting Jenkins Port to $Using:Port"
                $Config = Get-Content `
                    -Path "$using:InstallationPath\Jenkins.xml"
                $NewConfig = $Config `
                    -replace '--httpPort=[0-9]*\s',"--httpPort=$Using:Port "
                Set-Content `
                    -Path "$using:InstallationPath\Jenkins.xml" `
                    -Value $NewConfig `
                    -Force
                Write-Verbose -Verbose "Restarting Jenkins"
                Restart-Service `
                    -Name Jenkins
            }
            GetScript = {
                $Config = Get-Content `
                    -Path "$using:InstallationPath\Jenkins.xml"
                $Matches = @([regex]::matches($Config, "--httpPort=([0-9]*)\s", 'IgnoreCase'))
                $CurrentPort = $Matches.Groups[1].Value
                Return @{
                    'JenkinsPort' = $CurrentPort
                }
            }
            TestScript = {
                $Config = Get-Content `
                    -Path "$using:InstallationPath\Jenkins.xml"
                $Matches = @([regex]::matches($Config, "--httpPort=([0-9]*)\s", 'IgnoreCase'))
                $CurrentPort = $Matches.Groups[1].Value
        
                If ($Using:Port -ne $CurrentPort) {
                    # Jenkins port must be changed
                    Return $False
                }
                # Jenkins is already on correct port
                Return $True
            }
        }

        foreach ($pluginInfo in $plugins) {
            if (
                !$pluginInfo['version'] -or
                $pluginInfo['version'] -match 'latest'
            )
            {
                xRemoteFile $pluginInfo['Plugin_id'] {
                    DestinationPath = "$InstallationPath\plugins\$($pluginInfo['plugin_id']).hpi"
                    Uri = "http://updates.jenkins-ci.org/latest/$($pluginInfo['plugin_id']).hpi"
                }
            }
            else {
                xRemoteFile $pluginInfo['Plugin_id'] {
                    DestinationPath = "$InstallationPath\plugins\$($pluginInfo['plugin_id']).hpi"
                    Uri = "http://updates.jenkins-ci.org/download/plugins/$($pluginInfo['plugin_id'])/$($pluginInfo['version'])/$($pluginInfo['plugin_id']).hpi"
                }
            }
        }

        xRemoteFile pipelineStageViewPlugin {
            DestinationPath = "$InstallationPath\plugins\pipeline-stage-view.hpi"
            Uri = "http://archives.jenkins-ci.org/plugins/pipeline-stage-view/latest/pipeline-stage-view.hpi"
        }
}
