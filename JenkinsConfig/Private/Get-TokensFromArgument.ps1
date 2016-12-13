function Get-TokensFromArgument {
    <#
      .SYNOPSIS
      Formats a command argument object into a set of Tokens ([string[]]), based on an Argument definition file.

      .DESCRIPTION
      This command transforms Arguments object extracted based on a an Argument Definition file in JSON,
      into a list of command tokens (array of strings).

      .EXAMPLE
      [PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='client';} | Get-TokensFromArgument
      #output: -client
      # The formatter is defined in JavaOptions.definition.json

      .EXAMPLE
      $Arguments = ((Get-JenkinsJavaArguments -JenkinsXMLPath .\tests\Unit\resources\jenkins.xml).options | Get-ArgumentsFromTokens)
      $Tokens = $Arguments | Get-TokensFromArgument

      .PARAMETER Argument
      Argument Object as defined in the ArgumentDefinitionFile.
      The Argument Definition is selected by the first match between its TypeName property and the
      PSTypeNames[0] of the $Argument.
      The formater will be split in an array based on spaces, so that a formatter "-{0} {1}" returns 2 tokens
      Then each of those fomater will be used along with the values of the properties defined in the Argument definition
      using the formater operator:
      $token1 = ("$fromater1" -f $properties)
      $token2 = ("$fromater2" -f $properties)

      .PARAMETER ArgumentsDefinitionFile
      The Definition file (in JSON) defining the typeName of the argument, along with the properties,
      a way to extract them from a Token, and a way to format them back into an equivalent token.
      #>
    [cmdletBinding()]
    [OutputType('String')]
    Param(

        [Parameter(
            Mandatory
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
            )]
        [PSCustomObject]
        $Argument,

        [Parameter(
            ,ValueFromPipelineByPropertyName
            )]
        [io.FileInfo]
        $ArgumentsDefinitionFile = "$PSScriptRoot/../config/JavaOptions.definition.json"
    )

    begin {
        $defaultDefinitionFile = "$PSScriptRoot/../config/JavaOptions.definition.json"
        if (!(Test-path -Path $ArgumentsDefinitionFile)) {
            Write-Warning -Message ('{0} was not found, defaulting to {1}' -f 
                                    $ArgumentsDefinitionFile,$defaultDefinitionFile) 
            $ArgumentsDefinitionFile = $defaultDefinitionFile
        }
        $ArgumentsDefinition = Get-Content -Raw -Path $ArgumentsDefinitionFile | ConvertFrom-Json
    }

    Process {
        foreach ($CmdArg in $Argument) {
            $Definition = $ArgumentsDefinition |
                            Where-Object { $_.typeName -eq $CmdArg.PSTypeNames[0] } |
                            Select-Object -First 1
            
            $properties = @()
            foreach ($PropertyName in $Definition.properties) {
                $properties += $CmdArg.($PropertyName)
            }
            if ($Definition.next_token_as) {
                $properties += $CmdArg.($Definition.next_token_as)
            }
            
            $formaters = $Definition.formater -split '\s'
            foreach ($formater in $formaters) {
                Write-Output -inputObject ("$formater" -f $properties)
            }
        }
    }
}