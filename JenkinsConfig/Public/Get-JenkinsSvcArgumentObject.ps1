function Get-JenkinsSvcArgumentObject {
    <#
      .SYNOPSIS
      Returns a list of Jenkins.config.JavaParameter objects of the Jenkins.xml
      service.arguments node.

      .DESCRIPTION
      Looks up the Jenkins Arguments string in the Jenkins.xml,
      in the service.arguments Node an extract the different Java 
      Options,jar/class, and arguments as Tokens (array of strings).
      
      .EXAMPLE
      $object = Get-JenkinsSvcArgumentObject -JenkinsXMLPath C:\Jenkins\Jenkins.xml
      $object | convertto-Json
      
      .PARAMETER JenkinsXMLPath
      File path to the Jenkins XML configuration file. Default to C:\Program Files (x86)\Jenkins\Jenkins.xml

      .PARAMETER ServiceName
      Service to be used to resolve the JENKINS_HOME to find the Jenkins.xml file.
      #>
    [cmdletBinding(DefaultParameterSetName='ByServiceName')]
    [OutputType('Jenkins.config.SvcParameter[]')]
    Param(
        [Parameter(
            ValueFromPipelineByPropertyName,
            Position=0,
            ParameterSetName = 'ByJenkinsXmlFilePath'
            )]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]
        $JenkinsXMLPath = [IO.FileInfo]::new('C:/Program Files (x86)/Jenkins/Jenkins.xml'),

        [Parameter(
            ValueFromPipelineByPropertyName,
            Position=0,
            ParameterSetName = 'ByServiceName'
            )]
        [AllowNull()]
        [IO.FileInfo]
        $ServiceName = 'Jenkins'
    )
    
    Process {
            if ($PSCmdlet.ParameterSetName -eq 'ByServiceName') {
                $JenkinsHome = Get-JenkinsHomeFromSvcName -ServiceName $ServiceName
                Write-Verbose -Message ('Jenkins Home Resolved to {0}' -f $JenkinsHome)

                if (!($JenkinsXMLPath = [io.fileInfo](Join-Path -Path $JenkinsHome -ChildPath Jenkins.xml)) -or
                    !$JenkinsXMLPath.Exists) {
                    Throw ('Could not resolve path {0}\Jenkins.xml' -f $JenkinsHome)
                }
            }
            $JenkinsXml = Get-JenkinsXml -JenkinsXMLPath $JenkinsXMLPath -ErrorAction Continue

            $CommandLine = $JenkinsXml.Service.arguments

            Get-JavaCommandObjectFromTokenizedCommand -TokenizedCommand (
                    Get-TokenizedCommand -InputObject $CommandLine -RemoveEmptyToken
                  )
    }
}