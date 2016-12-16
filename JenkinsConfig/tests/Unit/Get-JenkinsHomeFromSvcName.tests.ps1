$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

function Get-CimInstance { Param($ClassName) }


Describe 'Get-JenkinsHomeFromSvcName' {

Mock -CommandName Get-CimInstance -MockWith {[PSCustomObject]@{Name='Jenkins';PathName='"C:\Program Files (x86)\Jenkins\jenkins.exe"'} }
  
  Context 'General context'   {

    It 'runs without errors' {
        { Get-JenkinsHomeFromSvcName } | Should Not Throw
    }

    It 'Returns the Service PathName parent'     {
      (Get-JenkinsHomeFromSvcName).FullName | Should Be 'C:\Program Files (x86)\Jenkins'
    }

    It 'Throw an error when the service id is wrong' {
        $guid = New-Guid
        { Get-JenkinsHomeFromSvcName -ServiceId $guid.Guid }| Should Throw
    }
  }
}
