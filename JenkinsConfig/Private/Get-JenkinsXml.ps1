function Get-JenkinsXml {
    <#
      .SYNOPSIS
      Attempts to load the Jenkins.xml config file and return an [xml] doc.
      
      .DESCRIPTION
      Get-JenkinsXml attempts to load the Jenkins.xml file from the provided path,
      if no path is provided, it will try 'C:/Program Files (x86)/Jenkins/Jenkins.xml'.

      .EXAMPLE
      $xml = Get-JenkinsXml -JenkinsXMLPath "$TestDrive/Jenkins.xml"
      
      .EXAMPLE
      Get-JenkinsXml -JenkinsXMLPath "Jenkins.xml"
      # Will lookup in "$pwd\Jenkins.xml"
      
      .PARAMETER JenkinsXMLPath
      The path to the Jenkins.xml file

      #>
    [cmdletBinding()]
    [OutputType('System.Xml.XmlDocument')]
    Param(
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
            )]
        [IO.FileInfo]
        $JenkinsXMLPath = [IO.FileInfo]::new('C:/Program Files (x86)/Jenkins/Jenkins.xml')
    )

    Process {
        foreach ($JenkinsConfig in $JenkinsXMLPath) {
            Write-Verbose -Message ('Verifying if file {0} exists or relative to {1}' -f $JenkinsConfig.FullName, $pwd.Path)
            $AlternativeJenkinsConfig = $null
            if (!$JenkinsConfig.Exists -and 
                !($AlternativeJenkinsConfig = [string](Resolve-Path -Path (Join-Path -Path $pwd.Path -ChildPath $JenkinsConfig) -ErrorAction SilentlyContinue))
                )
            {
                Throw ('The file specified {0} does not exist' -f $JenkinsConfig)
            }
            else {
                if($AlternativeJenkinsConfig) {
                    $JenkinsConfig = $AlternativeJenkinsConfig
                }
                Write-Verbose -Message ('File {0} exists. Loading XML in Memory' -f $JenkinsConfig) 
            }

            try {
                $JenkinsXml = New-object -TypeName xml
                $JenkinsXml.Load($JenkinsConfig)
                Write-Verbose -Message ('File {0} Loaded' -f $JenkinsConfig)
                Write-Output -InputObject $JenkinsXml
            }
            catch {
                Throw ('Error Opening or loading the Jenkins.xml: {0}' -f $_.Exception.Message)
            }
        }
    }
}

