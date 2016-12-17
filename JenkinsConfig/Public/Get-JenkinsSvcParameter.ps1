function Get-JenkinsSvcParameter {
    <#
      .SYNOPSIS
      Returns the Options or Arguments objects of the Jenkins.xml argument node.

      .DESCRIPTION
      Gets the content of the Jenkins.xml's Argument node and parse either the Options or the Arguments
      of the file, which defines the arguments passed to either the JVM or the Jenkins jar.

      .EXAMPLE
      $Params = @{
        JenkinsXMLPath = 'C:\Program Files (x86)\Jenkins\Jenkins.xml'
      }
      Get-JenkinsSvcParameter @Params

      .PARAMETER JavaOptionOrJarArgument
      Define which part of the Java command Argument from the Jenkins.xml you want to retrieve:
      Java [Options] -Jar JARNAME.Jar [Argument]

      .PARAMETER JenkinsXMLPath
      Specify the file location of the Jenkins.xml file to read, by default it will look within the JENKINS_HOME
      from the default service name.

      .PARAMETER ServiceName
      To lookup an installed Jenkins service, and find the JENKINS_HOME based on its executable's parent folder.

      .PARAMETER ArgumentsDefinitionFile
      To lookup an installed Jenkins service, and find the JENKINS_HOME based on its executable's parent folder.

      
      #>
    [cmdletBinding(DefaultParameterSetName='ByServiceName')]
    [OutputType('void')]
    Param(    
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
            )]
        [ValidateSet('JavaOption','JarArgument')]
        $JavaOptionOrJarArgument,

        [AllowNull()]
        [Parameter(
            ValueFromPipelineByPropertyName
            ,ParameterSetName='ByJenkinsXmlFile'
            )]
        [IO.FileInfo]
        $JenkinsXMLPath = $null,

        [ValidateScript({$null -eq $_ -or (Get-service -Name $_)})]
        [Parameter(
            ValueFromPipelineByPropertyName
            ,ParameterSetName='ByServiceName'
            )]
        [String]
        $ServiceName = $null,

        [Parameter(
            ValueFromPipelineByPropertyName
            )]
        [io.FileInfo]
        $ArgumentsDefinitionFile = $null
    )

    Process {
        if ($PSCmdlet.ParameterSetName -eq 'ByServiceName') {
            $JenkinsHome = Get-JenkinsHomeFromSvcName -ServiceId $serviceName
            $JenkinsXMLPath = Join-Path  -Path $JenkinsHome -ChildPath 'Jenkins.xml' -Resolve -ErrorAction Stop
        }

        switch ($JavaOptionOrJarArgument) {
            'JavaOption'  { 
                $ArgumentsProperty = 'Options'   
                $DefaultArgumentDefinitionFile = "$PSScriptRoot/../config/JavaOptions.definition.json"
            }
            'JarArgument' { 
                $ArgumentsProperty = 'Arguments' 
                $DefaultArgumentDefinitionFile = "$PSScriptRoot/../config/JenkinsArguments.definition.json"
            }
            Default {
                Throw ('JavaOptionOrJarArgument value {0} not recognized' -f $JavaOptionOrJarArgument)
            }
        }

        if (!$PSBoundParameters.ContainsKey('ArgumentsDefinitionFile')) {
            $ArgumentsDefinitionFile = $DefaultArgumentDefinitionFile
        }

        $JenkinsConfig = Get-jenkinsSvcConfig -JenkinsXMLPath $JenkinsXMLPath -ErrorAction Stop
        $CurrentArguments = Get-ArgumentFromToken -ArgumentToken $JenkinsConfig.Service.arguments.($ArgumentsProperty) -ArgumentsDefinitionFile $ArgumentsDefinitionFile
       
       Write-Output -InputObject $CurrentArguments
    }
}