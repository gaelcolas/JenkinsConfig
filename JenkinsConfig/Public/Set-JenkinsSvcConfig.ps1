function Set-JenkinsSvcConfig {
    <#
      .SYNOPSIS
      Write a configuration object to a Jenkins.xml file.

      .DESCRIPTION
      This function will create an Xml file if not existing, or will update an existing one with the values set in the
      Jenkins configuration object.

      .EXAMPLE
      $sampleConfigObject = [PSCustomObject]@{
                        PSTypeName = 'Jenkins.configuration'
                        Service = ([PSCustomObject]@{
                            id = 'Jenkins'
                            name = 'JenkinsName'
                            description = 'Jenkins service description'
                            env = [PSCustomObject]@{name='envName';value='envValue'}
                            executable='java'
                            arguments=$SampleArgumentObject
                            logmode = 'rotate'
                            onfailure= [PSCustomObject]@{action='restart'}
                        })
      $Params = @{
        ConfigurationObject = $sampleConfigObject
        JenkinsXMLPath = 'C:\Program Files (x86)\Jenkins\Jenkins.xml'
      }
      
      Set-JenkinsSvcConfig @Params

      .PARAMETER ConfigurationObject
      Object representing the values of the Jenkins.xml in a simpler format than xml.

      .PARAMETER JenkinsXMLPath
      Specify the file location of the Jenkins.xml file to read, by default it will look within the JENKINS_HOME
      from the default service name.
      
      #>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact='Medium'
        )]
    Param (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
            )]
        [PSTypeName('Jenkins.configuration')]
        $ConfigurationObject,
         
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
            )]
        [ValidateNotNullOrEmpty()]
        [io.FileInfo]
        $JenkinsXMLPath
    )
    
    #If file empty, Create New XML document
    # else load JenkinsXMLPath
    begin {
        if ((Test-Path $JenkinsXMLPath)) {
            $NewJenkinsXml = New-Object -TypeName System.Xml.XmlDocument
            $NewJenkinsXml.Load($JenkinsXMLPath.FullName)
            $RootNode = $NewJenkinsXml.ChildNodes | Where-Object { $_.name -ne '#comment' }
        }
        else {
            $null = New-Item -ItemType File -Path $JenkinsXMLPath -Force -ErrorAction Stop
            $NewJenkinsXml = New-Object -TypeName System.Xml.XmlDocument
            $RootNode = $NewJenkinsXml.CreateElement("Service")
            [void]$NewJenkinsXml.AppendChild($RootNode)
        }

        if (!$NewJenkinsXml.service.id) {
            $idNode = $NewJenkinsXml.CreateElement('id')
             [void]$RootNode.AppendChild($idNode)
        }

        if (!$NewJenkinsXml.service['name']) {
            $nameNode = $NewJenkinsXml.CreateElement('name')
            [void]$RootNode.AppendChild($nameNode)
        }

        if (!$NewJenkinsXml.service.description) {
            $descriptionNode = $NewJenkinsXml.CreateElement('description')
            [void]$RootNode.AppendChild($descriptionNode)
        }

        if (!$NewJenkinsXml.service.env) {
            $envNode= $NewJenkinsXml.CreateElement('env')
                $envNameAttr = $NewJenkinsXml.CreateAttribute('name')
                $envValueAttr = $NewJenkinsXml.CreateAttribute('value')
                    [void]$envNode.Attributes.Append($envNameAttr)
                    [void]$envNode.Attributes.Append($envValueAttr)
            [void]$RootNode.AppendChild($envNode)
        }

        if (!$NewJenkinsXml.service.executable) {
            $execNode = $NewJenkinsXml.CreateElement('executable')
            [void]$RootNode.AppendChild($execNode)
        }

        if (!$NewJenkinsXml.service.arguments) {
            $argumentsNode = $NewJenkinsXml.CreateElement('arguments')
            [void]$RootNode.AppendChild($argumentsNode)
        }

        if (!$NewJenkinsXml.service.logmode) {
            $logmodeNode = $NewJenkinsXml.CreateElement('logmode')
            [void]$RootNode.AppendChild($logmodeNode)
        }

        if (!$NewJenkinsXml.service.onfailure) {
            $onfailureNode = $NewJenkinsXml.CreateElement('onfailure')
                $onfailureActionAttr = $NewJenkinsXml.CreateAttribute('action')
                [void]$onfailureNode.Attributes.Append($onfailureActionAttr)
                [void]$RootNode.AppendChild($onfailureNode)
        }
    }

    Process {
        $arguments =  (Get-JavaCommandFromJavaCommandObject -JavaCommandObject $ConfigurationObject.Service.arguments)
        
        $NewJenkinsXml.Service['id'].InnerText        = $ConfigurationObject.Service.id
        $NewJenkinsXml.Service['name'].InnerText      = $ConfigurationObject.Service.name
        $NewJenkinsXml.Service.description            = $ConfigurationObject.Service.description
        $NewJenkinsXml.Service.env.name               = $ConfigurationObject.Service.env.name
        $NewJenkinsXml.Service.env.value              = $ConfigurationObject.Service.env.value
        $NewJenkinsXml.service.executable             = $ConfigurationObject.Service.executable
        $NewJenkinsXml.service['arguments'].InnerText = $arguments
        $NewJenkinsXml.service.logmode                = $ConfigurationObject.Service.logmode
        $NewJenkinsXml.service.onfailure.action       = $ConfigurationObject.Service.onfailure.action
    }

    end {
        if($PSCmdlet.ShouldProcess($JenkinsXMLPath)) {
            $NewJenkinsXml.Save($JenkinsXMLPath.FullName)
        }
    }
}

