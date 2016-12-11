
function Get-JenkinsConfigObject {
    <#
      .SYNOPSIS
      Describe the function here
      .DESCRIPTION
      Describe the function in more detail
      .EXAMPLE
      Give an example of how to use it
      .EXAMPLE
      Give another example of how to use it
      .PARAMETER Param1
      The param1
      .PARAMETER param2
      The second param
      #>
    [cmdletBinding()]
    [OutputType('PSCustomObject')]
    Param(
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
            )]
        [IO.FileInfo]
        $JenkinsXMLPath = [IO.FileInfo]::new('C:/Program Files (x86)/Jenkins/Jenkins.xml')
    )

    process {
        foreach ($JenkinsConfig in $JenkinsXMLPath) {
            $Arguments = Get-JenkinsJavaArguments -JenkinsXMLPath .\Jenkins\tests\jenkins.xml
            $JenkinsXml = Get-JenkinsXml -JenkinsXMLPath $JenkinsConfig -ErrorAction Continue

            #Constructing a PSObject out of the Parsed Info (allows easier edit and JSON comparison).
            Write-Output ([PSCustomObject]@{
                PSTypeName = 'Jenkins.configuration'
                'Service' = [PSCustomObject]@{
                    PSTypeName    = 'Jenkins.xml.Service'
                    'id'          = $JenkinsXml.Service.id
                    'name'        = $JenkinsXml.Service.name
                    'description' = $JenkinsXml.Service.description
                    'env'         = [PSCustomObject]@{
                        name=$JenkinsXml.Service.env.name
                        value= $JenkinsXml.Service.env.value
                    }
                    'executable'  = $JenkinsXml.service.executable
                    'arguments'   = $Arguments
                    'logmode'     = $JenkinsXml.service.logmode
                    'onfailure'   = [PSCustomObject]@{
                        'action' = $JenkinsXml.service.onfailure.action
                    }
                }
            })
        }
    }

}