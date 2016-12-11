function Get-JavaCommandObjectFromTokenizedCommand {
    <#
      .SYNOPSIS
      Create an Object from a Tokenized Command line

      .DESCRIPTION
      The command will look into the Tokens of a Java (javaw) command and
      decompose it into an object for easy comparison and manipulation.
      It allows to parse the commands with common format:
        java [ options ] class [ arguments ]
        java [ options ] -jar file.jar [ arguments ]
        javaw [ options ] class [ arguments ]
        javaw [ options ] -jar file.jar [ arguments ]
      Into a PSObject.

      .EXAMPLE
      $TokenizedCommand = @('Java.exe','-XOption1','-Doption2=value2','-Jar','Jenkins.jar','--argument1','--argument2')
      Get-JavaCommandObjectFromTokenizedCommand -TokenizedCommand $TokenizedCommand

      .PARAMETER TokenizedCommand
      This parameter accepts a Tokenized command (as an array of strings).
      For the command: Java.exe -XOption1 -Doption2="Value with space" -Jar Jenkins.jar --argument1 --argument2
      The Tokenized version would be: @('Java.exe','-XOption1','-Doption2="Value with space"','-Jar','Jenkins.jar','--argument1','--argument2')

      #>
    [cmdletBinding()]
    [OutputType('PSCustomObject')]
    Param(
        [Parameter(
            Mandatory
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
            )]
        [string[]]
        $TokenizedCommand
    )

    Process {

        $CommandObj = [PSCustomObject]@{
            PSTypeName   = 'Java.CommandObject'
            'Executable' = $null
            'Options'    = $null
            'isJar'      = $false
            'ClassOrJar' = $null
            'Arguments'  = @()
        }

        $OptionsStack = @()
        foreach ($cmdToken in $TokenizedCommand) {
            $cmdToken = $cmdToken.Trim()
            if ($CommandObj.Executable -eq $null) {
                if ($cmdToken -match 'javaw?.{0,4}$') {
                    Write-Verbose -message ('Found Executable {0}' -f $cmdToken)
                    $CommandObj.Executable = $cmdToken
                }
                else {
                    Write-Verbose -message 'No Executable in this command'
                    $CommandObj.Executable = [string]::Empty
                    $OptionsStack += $cmdToken
                }
            }
            elseif($CommandObj.Executable -ne $null -and
                   $CommandObj.Options -eq $null
                   ) {
                if ($cmdToken -match '^-jar$'){
                    Write-Verbose -Message 'Command is running a JAR'
                    $CommandObj.isJar = $true
                } #Handle -cp or -classpath here then next argument to close off
                elseif(!$isClassPath -and $cmdToken -match '^-cp|-classpath$') {
                    Write-Verbose -Message 'ClassPath detected, stacking its argument'
                    $isClassPath = $true
                    $OptionsStack += $cmdToken
                }
                elseif($isClassPath) {
                    Write-Verbose -Message "ClassPath argument= $cmdToken, Closing classPath Stack"
                    $isClassPath = $false
                    $OptionsStack += $cmdToken
                }
                elseif($cmdToken -match '^-') {
                    Write-Verbose -Message ('Adding Token {0} to the Java Options' -f $cmdToken)
                    $OptionsStack += $cmdToken
                }
                else {
                    if($OptionsStack) {
                        $CommandObj.Options = $OptionsStack
                    }
                    else {
                        Write-Verbose -Message 'No options found in the command'
                        $CommandObj.Options = [string[]]@()
                    }
                    Write-Verbose -Message ('The ClassOrJar is {0}' -f $cmdToken)
                    $CommandObj.ClassOrJar = $cmdToken
                }
            }
            else{
                Write-Verbose -Message ('Adding Token {0} to the Arguments' -f $cmdToken)
                $CommandObj.Arguments += $cmdToken
            }
        }
        
        if (!$CommandObj.Executable -and !$CommandObj.Options -and
             !$CommandObj.ClassOrJar -and !$CommandObj.Arguments) {
             Throw 'Could not decompose the given command.'
        }
        else {
            Write-Output -InputObject $CommandObj
        }
    }
}
