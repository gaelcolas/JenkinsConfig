$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

Describe 'Get-JavaCommandObjectFromTokenizedCommand' {

  Context 'Java -Jar command example with option and args'   {
    $testCommand = @('Java.exe',
                       '-XOption1','-Doption2=value2',
                       '-Jar',
                       'Jenkins.jar',
                       '--argument1','--argument2')

    $expectedResult = [PSCustomObject]@{
        Executable = $testCommand[0]
        Options    = $testCommand[1..2]
        isJar      = $testCommand -contains '-jar'
        ClassOrJar = $testCommand[4]
        Arguments  = $testCommand[5..6]
    }

    It 'runs without errors' {
        { Get-JavaCommandObjectFromTokenizedCommand -TokenizedCommand $testCommand } | Should Not Throw
    }

    It 'Throw when TokenizedCommand argument is null'     {
        { Get-JavaCommandObjectFromTokenizedCommand -TokenizedCommand $null } | Should Throw
    }

    It 'Throw when TokenizedCommand is invalid'     {
        { Get-JavaCommandObjectFromTokenizedCommand -TokenizedCommand ($testCommand -join ' ') } | Should Throw
    }

    It 'Gives the expected result object' {
        $testResult = Get-JavaCommandObjectFromTokenizedCommand -TokenizedCommand $testCommand
        $compare = Compare-Object -ReferenceObject $testResult -DifferenceObject $expectedResult -Property Executable,Options,isJar,ClassOrJar,Arguments
        $compare | Should BeNullOrEmpty
    }
  }

  Context 'Testing list of cases' {
    
    $listCommands = @(
         @{test = @('Java.exe','-XOption1','-Doption2=value2','-Jar','Jenkins.jar','--argument1','--argument2')
           result= [PSCustomObject]@{
                Executable = 'Java.exe'
                Options    = '-XOption1','-Doption2=value2'
                isJar      = $true
                ClassOrJar = 'Jenkins.jar'
                Arguments  = '--argument1','--argument2'
            }
        }
        ,@{test = @('-XOption1','-Doption2=value2','Class','argument1','argument2')
           result= [PSCustomObject]@{
                Executable = '' #supports when there's no executable included
                Options    = '-XOption1','-Doption2=value2'
                isJar      = $false
                ClassOrJar = 'Class'
                Arguments  = 'argument1','argument2'
            }
       }
       #From https://docs.oracle.com/javase/8/docs/technotes/tools/windows/classpath.html
       #java -classpath C:\java\MyClasses\myclasses.jar utility.myapp.Cool
       , @{test = @('java','-classpath','C:\java\MyClasses\myclasses.jar','utility.myapp.Cool')
           result= [PSCustomObject]@{
                Executable = 'java'
                Options    = '-classpath','C:\java\MyClasses\myclasses.jar'
                isJar      = $false
                ClassOrJar = 'utility.myapp.Cool'
                Arguments  = ''
            }
        }
        , @{test = @('java','-cp','C:\java\MyClasses;C:\java\OtherClasses','utility.myapp.Cool')
           result= [PSCustomObject]@{
                Executable = 'java'
                Options    = '-cp','C:\java\MyClasses;C:\java\OtherClasses'
                isJar      = $false
                ClassOrJar = 'utility.myapp.Cool'
                Arguments  = ''
            }
        }
        <#, @{test = @('Java.exe','-XOption1','-Doption2=value2','-Jar','Jenkins.jar','--argument1','--argument2')
           result= [PSCustomObject]@{
                Executable = 'Java'
                Options    = '-XOption1','-Doption2=value2'
                isJar      = $true
                ClassOrJar = 'Jenkins.jar'
                Arguments  = '--argument1','--argument2'
            }
        }#>
        #,@{test = @(); result=@()}
    )

    foreach ($cmd in $ListCommands) {
        It "Test the command: $($cmd.test -join ' ')" {
            $testResult = Get-JavaCommandObjectFromTokenizedCommand -TokenizedCommand $cmd.test
            $compare = Compare-Object -ReferenceObject $testResult -DifferenceObject $cmd.result -Property Executable,Options,isJar,ClassOrJar,Arguments
            $compare | Should BeNullOrEmpty
        }
    }
  
  }
}
