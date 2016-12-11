$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder


Describe 'Get-TokenizedCommand' {
    $testString = 'Java.exe -Xrs -Xmx256m -Dhudson.lifecycle=hudson.lifecycle.WindowsServiceLifecycle -Djenkins.install.runSetupWizard=false -Jar "%BASE%\jenkins.war" --httpPort=8080 --webroot="%BASE%\war"'
    $ExpectedResult = @('Java.exe', '-Xrs', '-Xmx256m', '-Dhudson.lifecycle=hudson.lifecycle.WindowsServiceLifecycle', '-Djenkins.install.runSetupWizard=false', '-Jar', '"%BASE%\jenkins.war"', '--httpPort=8080', '--webroot="%BASE%\war"')

  Context 'Using Jenkins cmd example'   {

    It 'runs without errors via pipeline' {
        { $testString | Get-TokenizedCommand } | Should Not Throw
    }
    
    It 'runs without errors via multiple input in pipeline' {
        { $testString,$testString  | Get-TokenizedCommand } | Should Not Throw
    }
    
    It 'runs without errors via parameter' {
        { Get-TokenizedCommand -InputObject $testString} | Should Not Throw
    }

    It 'Throw when the imput object is null' {
      { Get-TokenizedCommand -InputObject $null } | Should Throw
    }

    It 'Tokenize the test string correctly' {
        Get-TokenizedCommand $testString | Should be $ExpectedResult
    }

    $testString = $testString -replace '\s','  '

    It 'Tokenize and do not return empty Tokens' {
        Get-TokenizedCommand $testString -RemoveEmptyToken | Should be $ExpectedResult
    }
  }

  Context 'Testing different possibilities of Get-TokenizedCommand' {

    It 'Should handle space within quoted Token' {
        $expect= @('-Xrs','-Jar','"C:\Program Files\Jenkins\Jenkins.Jar"')
        $result = (Get-TokenizedCommand '-Xrs -Jar "C:\Program Files\Jenkins\Jenkins.Jar"')
        $compare = (Compare-Object -ReferenceObject $expect -DifferenceObject $result) 

        $Compare | Should BeNullOrEmpty
    }

    It 'Should handle key:value="a b" args where value has spaces within quotes' {
        $expect= @('-Xrs','-Jar','-property:key="C:\This Value\has\spaces"')
        $result = (Get-TokenizedCommand '-Xrs -Jar -property:key="C:\This Value\has\spaces"')
        $compare = (Compare-Object -ReferenceObject $expect -DifferenceObject $result) 
        $Compare | Should BeNullOrEmpty
    }

    It 'Should leave the same number of spaces in quoted arguments' {
        (Get-TokenizedCommand 'a -property:key="a   a"'
            )[1].ToCharArray().Where({$_ -eq ' '}).count | Should be 3
    }
  }

}
