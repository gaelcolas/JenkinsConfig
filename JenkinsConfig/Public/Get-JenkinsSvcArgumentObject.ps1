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
      #>
    [cmdletBinding()]
    [OutputType('Jenkins.config.SvcParameter[]')]
    Param(
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position=0
            )]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]
        $JenkinsXMLPath = [IO.FileInfo]::new('C:/Program Files (x86)/Jenkins/Jenkins.xml')
    )
    
    Process {
        foreach ($JenkinsConfig in $JenkinsXMLPath) {
            $JenkinsXml = Get-JenkinsXml -JenkinsXMLPath $JenkinsConfig -ErrorAction Continue

            $CommandLine = $JenkinsXml.Service.arguments

            Get-JavaCommandObjectFromTokenizedCommand -TokenizedCommand (
                    Get-TokenizedCommand -InputObject $CommandLine -RemoveEmptyToken
                  )
        }
    }
}