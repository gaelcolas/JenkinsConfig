function Invoke-JenkinsCommand {
    <#
      .SYNOPSIS
      Describe the function here
      
      .DESCRIPTION
      Describe the function in more detail
      java -jar jenkins-cli.jar [-s JENKINS_URL] command [options...] [arguments...]

      .EXAMPLE
      Give an example of how to use it
      
      .EXAMPLE
      Give another example of how to use it
      
      .PARAMETER Param1
      The param1
      
      .PARAMETER param2
      The second param
      #>
    [cmdletBinding(
            SupportsShouldProcess=$true,
            ConfirmImpact='Low',
            DefaultParameterSetName='AuthAsAnonymous'
            )]
    [OutputType('PSCustomObject')]
    Param(
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
            )]
        [string[]]
        $Command,

        [Parameter(
            ValueFromPipelineByPropertyName
            )]
        [string[]]
        $CommandArgument = $null,

        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
            ,ParameterSetName='AuthBySshPublicKey'
            )]
        [io.fileInfo]
        $PublicKeyFile,

        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
            ,ParameterSetName='AuthByCredential'
            )]
        [PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
            ,ParameterSetName='AuthByPasswordFile'
            )]
        [string]
        $Username,
        
        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
            ,ParameterSetName='AuthByPasswordFile'
            )]
        [AllowNull()]
        [io.FileInfo]
        $PasswordFile,

        [Parameter(
            ValueFromPipelineByPropertyName
            ,ParameterSetName='AuthAsAnonymous'
            )]
        [switch]
        $NoSecurity,

        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
            )]
        [uri]
        $JenkinsUri,

        [Parameter(
            ValueFromPipelineByPropertyName
            )]
        [io.FileInfo]
        $JavaExe,
        
        [Parameter(
            ValueFromPipelineByPropertyName
            )]
        [string]
        $JenkinsServiceId = 'Jenkins',

        [Parameter(
            ValueFromPipeline
            ,ValueFromPipelineByPropertyName
            )]
        [string]
        [Alias('STDIN')]
        $InputObject,

        [Parameter(
            ValueFromPipelineByPropertyName
            )]
        [io.fileInfo]
        $JenkinsCliJar

    )

    begin {
        if (!$JavaExe.Exists -and !($JavaExe = (Get-Command -Name 'java' -ErrorAction SilentlyContinue).Path)) {
                Write-Verbose -Message 'Java command not found, trying to find jre in JENKINS_HOME'
                if ($JenkinsHome = Get-JenkinsHomeFromSvcName -ServiceId $JenkinsServiceId) {
                    $JavaExe = Join-path -Path $JenkinsHome -ChildPath 'jre/bin/java.exe' -Resolve -ErrorAction Stop
                }
                else {
                    Throw 'Java.exe not found in Path, and Jenkins install not detected. Please provide path to Java.exe'
                }
        }

        if (!$PSBoundParameters.ContainsKey('JenkinsCliJar') -or !$JenkinsCliJar.Exists) {
            Write-Debug -Message 'No Jenkins-cli.jar file provided or does ont exist, Trying to resolve or download'
            #Find JenkinsHome if Jenkins service is installed, then the the jenkins-cli.jar is war/WEB-INF/
            if ($JenkinsHome = Get-JenkinsHomeFromSvcName -ServiceId $JenkinsServiceId -ErrorAction SilentlyContinue) {
                Write-Debug -Message ('Jenkins Home found on this node, from service name {0}' -f $JenkinsServiceId)
                $JenkinsCliJar = Join-path -Path $JenkinsHome -ChildPath 'war/WEB-INF/jenkins-cli.jar' -Resolve -ErrorAction Stop
                Write-Verbose -Message ('File found in {0}' -f $JenkinsCliJar.FullName)
            }
            elseif (!($JenkinsCliJar = (Join-path -Path $Env:AppData -ChildPath '/JenkinsConfig/Jenkins-cli.jar' -Resolve -ErrorAction SilentlyContinue))) {
                #Not previously downloaded, Download Jenkins CLI in $Env:AppData\JenkinsConfig
                Write-Verbose -Message ('Attempting to download the file from {0}' -f $JenkinsUri)
                $DownloadTo = New-Item -ItemType Directory -Path (Join-path -Path $Env:AppData -ChildPath '/JenkinsConfig/') -Force
                $JenkinsCliJar = (Join-Path -Path $DownloadTo -ChildPath 'Jenkins-cli.jar')
                $null = Invoke-WebRequest -UseBasicParsing -Uri "$JenkinsUri/war/WEB-INF/jenkins-cli.jar" -OutFile $JenkinsCliJar -ErrorAction Stop
                if (!(Test-Path -Path $JenkinsCliJar)) {
                    Throw ('Error downloading the Jenkins-cli.jar file from {0}/war/WEB-INF/jenkins-cli.jar' -f $JenkinsUri)
                }
            }
        }

        $jenkinsCommand = @('-jar',$JenkinsCliJar.FullName,'-s',$JenkinsUri.AbsoluteUri)
        $jenkinsCommand += $Command

        if ($CommandArgument) { $jenkinsCommand += $CommandArgument}

        switch ($pscmdlet.ParameterSetName) {
            'AuthByCredential'   {
                $JenkinsCommand += '--username',$Credential.UserName,'--password',$Credential.GetNetworkCredential().password
            }
            
            'AuthByPasswordFile' {
                if ($null -eq $PasswordFile -and ($JenkinsHome = Get-JenkinsHomeFromSvcName -ServiceId $JenkinsServiceId -ErrorAction SilentlyContinue)) {
                    #get InitialAdminPassword
                    $PasswordFile = Join-Path -Path $JenkinsHome -ChildPath 'secrets/initialAdminPassword' -Resolve -ErrorAction Stop
                }
                $JenkinsCommand += '--username',$Username,'--password-file',"`"$($PasswordFile.FullName)`""
            }
            
            'AuthBySshPublicKey' {
                if (!$PublicKeyFile.Exists) {
                    Throw ('Public Key file not found at {0}' -f $PublicKeyFile.FullName)
                }
                else {
                    Write-Debug -Message ('Public key found at {0}' -f $PublicKeyFile.FullName)
                    $JenkinsCommand += '-i',"`"$($PublicKeyFile.FullName)`""
                }
            }
            default {
                # Auth by ssh public key if present (~/.ssh/identity, ~/.ssh/id_dsa, ~/.ssh/id_rsa)
                # fall back to anonymous
                Write-Verbose -Message 'Falling back to Public key Auth or Anonymous'
            }
        }
    }

    Process {
        
        if ($pscmdlet.ShouldProcess(('java -jar jenkins-cli.jar {0} {1}' -f ($Command -join ' '), ($CommandArgument -join ' ') ))) {
            if ($InputObject) {
                Write-Verbose -Message ('Executing command {0}| & {1} {2}' -f $Input,$JavaExe,($JenkinsCommand -join ' '))
                $result = [string]($Input | & $JavaExe $jenkinsCommand *>&1 )
            }
            else {
                Write-Verbose -Message ('Executing command without STDIN.')
                Write-Verbose -Message ('& {0} {1}' -f $JavaExe,($jenkinsCommand -join ' '))
                $RawResult = & $JavaExe $jenkinsCommand *>&1
                #here goes a dirty hack to reformat the ErrorRecords received from Java...
                #might be an issue with the help jenkins-cli command
                $result = [string](($RawResult | ? { $_ -notmatch '^\s*$'  } ) -join "`r`n")
            }

            if ($LASTEXITCODE -ne 0) {
                Write-Warning -Message ('The command was not successful, Last Exit Code = {0}' -f $LASTEXITCODE)
                throw $result
            }
            else{
                try {
                    $ObjectResult = ConvertFrom-Json -InputObject $result -ErrorAction Stop
                    Write-Debug 'Output is JSON, returning the object'
                    Write-Output -InputObject $ObjectResult
                }
                catch {
                    Write-Output -InputObject $result
                }
            }
        }
    }
}