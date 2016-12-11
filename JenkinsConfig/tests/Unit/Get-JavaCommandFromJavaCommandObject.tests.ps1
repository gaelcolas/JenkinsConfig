$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

Describe 'Get-JavaCommandFromJavaCommandObject' {

  Context 'General context'   {
    $ExampleObject = [PSCustomObject]@{
                PSTypeName = 'Java.CommandObject'
                Executable = '' #supports when there's no executable included
                Options    = '-XOption1','-Doption2=value2'
                isJar      = $false
                ClassOrJar = 'Class'
                Arguments  = 'argument1','argument2'
    }
    It 'runs without errors' {
        { Get-JavaCommandFromJavaCommandObject -JavaCommandObject $ExampleObject } | Should Not Throw
    }

    It 'returns a string' {
      $ExampleObject | Get-JavaCommandFromJavaCommandObject | Should BeOfType 'string'
    }

    It 'Returns the expected result' {
        $ExampleObject | Get-JavaCommandFromJavaCommandObject | Should beExactly '-XOption1 -Doption2=value2 Class argument1 argument2'
    }
  }

  Context 'Run a list of commands and test result' {
  
    $ListOfTests = @(
        @{testInput       = [PSCustomObject]@{
                                PSTypeName = 'Java.CommandObject'
                                Executable = '' #supports when there's no executable included
                                Options    = '-XOption1','-Doption2=value2'
                                isJar      = $false
                                ClassOrJar = 'Class'
                                Arguments  = 'argument1','argument2'
                            }
           expectedResult = '-XOption1 -Doption2=value2 Class argument1 argument2'
        }
        <#,@{testInput       = [PSCustomObject]@{
                                PSTypeName = 'Java.CommandObject'
                                Executable = '' #supports when there's no executable included
                                Options    = '-XOption1','-Doption2=value2'
                                isJar      = $false
                                ClassOrJar = 'Class'
                                Arguments  = 'argument1','argument2'
                            }
           expectedResult = '-XOption1 -Doption2=value2 Class argument1 argument2'
        }#>

    )
    foreach ($test in $ListOfTests) {
        it "Should return $($test.expectedResult)" {
            $test.testInput | Get-JavaCommandFromJavaCommandObject | Should beExactly $test.expectedResult
        }
    }
  }
}
