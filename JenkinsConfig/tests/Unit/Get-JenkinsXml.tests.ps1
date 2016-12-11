$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

Set-StrictMode -Version Latest

Describe 'Get-JenkinsXml' {
Copy-Item -Path ('{0}/Resources/jenkins.xml' -f $here) -Destination TestDrive:/Jenkins.xml
  Context 'General context'   {

    It 'Errors when no file found' {
        { Get-JenkinsXml -JenkinsXMLPath "$TestDrive/ThisDoesNotExist.xml" } | Should Throw
    }

    It 'runs without errors' {
        #Need to use $TestDrive because the xml Load is done via the .Net method
        { Get-JenkinsXml -JenkinsXMLPath "$TestDrive/Jenkins.xml" } | Should Not Throw
    }

    It 'returns an XML document for existing file'     {
      Get-JenkinsXml -JenkinsXMLPath "$TestDrive/Jenkins.xml" | Should BeOfType System.Xml.XmlDocument
    }

    It 'XML has a Service Node, and in turn id,name,description,env[],executable,arguments,logmode,onfailure' {
        $xml = Get-JenkinsXml -JenkinsXMLPath "$TestDrive/Jenkins.xml"

        $xml.Service                | Should not BeNullOrEmpty
        $xml.Service['id']          | Should not BeNullOrEmpty
        $xml.Service['name']        | Should not BeNullOrEmpty
        $xml.Service['description'] | Should not BeNullOrEmpty
        $xml.Service['executable']  | Should not BeNullOrEmpty
        $xml.Service['arguments']   | Should not BeNullOrEmpty
        $xml.Service['logmode']     | Should not BeNullOrEmpty
        $xml.Service['onfailure']   | Should not BeNullOrEmpty
    }
  }
}
