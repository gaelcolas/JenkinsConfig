function Set-JenkinsSvcConfig {
    [CmdletBinding()]
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
        $FilePath
    )
    
    #If file empty, Create New XML document
    # else load FilePath
    begin {
        if ((Test-Path $FilePath)) {
            $NewJenkinsXml = New-Object -TypeName System.Xml.XmlDocument
            $NewJenkinsXml.Load($FilePath.FullName)
            $RootNode = $NewJenkinsXml.ChildNodes | ? name -ne '#comment'
        }
        else {
            $FileInfo = New-Item -ItemType File -Path $FilePath -Force -ErrorAction Stop
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
        #$NewJenkinsXml.Save($FilePath.FullName)
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
        $NewJenkinsXml.Save($FilePath.FullName)
    }
}

