function Get-JenkinsJavaArguments {
    <#
      .SYNOPSIS
      Looks up the Jenkins Arguments in the XML at service.arguments and
      split them into an object

      .DESCRIPTION
      Describe the function in more detail
      
      .EXAMPLE
      Give an example of how to use it
      
      .EXAMPLE
      Give another example of how to use it
      
      .PARAMETER Param1
      The param1
      #>
    [cmdletBinding()]
    [OutputType('Jenkins.config.JavaArguments')]
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