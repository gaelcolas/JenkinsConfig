function Get-JavaCommandFromJavaCommandObject {
    <#
      .SYNOPSIS
      Transforms the JavaCommandObject (PSCustomObject) into a string

      .DESCRIPTION
      This command assembles the command object properties into a Java command,
      respecting the order of the elements, and appending the -Jar when needed:
        java [ options ] class [ arguments ]
        java [ options ] -jar file.jar [ arguments ]
        javaw [ options ] class [ arguments ]
        javaw [ options ] -jar file.jar [ arguments ]

      .EXAMPLE
      $ExampleObject = [PSCustomObject]@{
                PSTypeName = 'Java.CommandObject'
                Executable = '' #supports when there's no executable included
                Options    = '-XOption1','-Doption2=value2'
                isJar      = $false
                ClassOrJar = 'Class'
                Arguments  = 'argument1','argument2'
      }
      Get-JavaCommandFromJavaCommandObject -JavaCommandObject $ExampleObject
      #Output: '-XOption1 -Doption2=value2 Class argument1 argument2'

      .PARAMETER JavaCommandObject
      Accepts custom object with a Type of Java.CommandObject as represented in the example
      of this command.

      #>
    [cmdletBinding()]
    [OutputType('string')]
    Param(
        [Parameter(
            Mandatory
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
            )]
        [PSTypeName('Java.CommandObject')]
        [PSCustomObject]
        $JavaCommandObject
    )

    Process {
        foreach ($CmdObject in $JavaCommandObject) {
            $JenkinsArgs = foreach ($section in 'executable','Options','ClassOrJar','Arguments') {
                if ($section -eq 'ClassOrJar' -and $CmdObject.isJar) {
                    Write-Output ('-jar {0}' -f $CmdObject.$section)
                }
                else {
                    Write-Output ($CmdObject.($Section) -join ' ')
                }
            }
            Write-Output -InputObject ($JenkinsArgs -join ' ')
        }
    }
}