function Get-JenkinsSvcConfig {
    <#
      .SYNOPSIS
      Reads a Jenkins.xml file and transforms to an object for manipulation.

      .DESCRIPTION
      This command Loads the specified Jenkins.xml that configures the windows service,
      into xml document object and extract some information as a Custom object of 
      PSTypeName [Jenkins.configuration].
      This object as the service, id, name, description, env, executable, arguments, logmode, onfailure properties.
      The Arguments property is a [PSCustomObject] of PSTypeName = [Java.CommandObject], defined
      in the command Get-JavaCommandObjectFromTokenizedCommand.

      .EXAMPLE
      Get-JenkinsSvcConfig -JenkinsXMLPath 'C:\Program Files (x86)\Jenkins\Jenkins.xml'

      .EXAMPLE
      $JenkinsSvcConfig = Get-JenkinsSvcConfig -JenkinsXMLPath 'C:\Program Files (x86)\Jenkins\Jenkins.xml'
      $JenkinsSvcConfig.service.Arguments = '--httpPort:8080','--webroot="%BASE%\war"'
      Set-JenkinsSvcConfig -ConfigurationObject $JenkinsSvcConfig -JenkinsXMLPath C:\Jenkins.xml

      .PARAMETER JenkinsXMLPath
      Path to the Jenkins.xml configuration. By default it uses 'C:\Program Files (x86)\Jenkins\Jenkins.xml'

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
            $JenkinsXml = Get-JenkinsXml -JenkinsXMLPath $JenkinsConfig -ErrorAction Continue
            $Arguments = Get-JenkinsSvcArgumentObject -JenkinsXMLPath $JenkinsXMLPath

            #Constructing a PSObject out of the Parsed Info (allows easier manipulation).
            #TODO: support a list of Env variable
            Write-Output -InputObject ([PSCustomObject]@{
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