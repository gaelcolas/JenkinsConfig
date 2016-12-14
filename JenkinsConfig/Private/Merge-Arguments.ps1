function Merge-Arguments {
    <#
      .SYNOPSIS
      Merges two lists of arguments according to specified behavior.

      .DESCRIPTION
      The Merge-Arguments command merges two lists of Argument objects together, following a
      specified resolution behavior (default is UpdateAndAdd).

      To identify matching arguments with different values, this command relies on the 'property' and 'key'
      properties of that object by default, but can be set either in the ArgumentDefinitionFile with the
      property MatchOn, or overriden by the MatchOn parameter of the command.

      If the MatchOn value contains 'TypeName' it will pre-filter the ExistingArguments based on their PSCustomObject
      TypeName (the top one only).

      .EXAMPLE
      $param = @{
        UpdateSource = @([PSCustomObject]@{PSTypeName='Java.Option.DPropertyValue';property='property';value='property'})
        ExistingArguments = @([PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='client';},[PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='server';},[PSCustomObject]@{PSTypeName='Java.Option.DPropertyValue';property='property';value='value'})
        ResolutionBehavior = 'UpdateOnly'
      }

      $mergedArgs = Merge-Arguments @param
      #$mergedArgs = @([PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='client';},[PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='server';},[PSCustomObject]@{PSTypeName='Java.Option.DPropertyValue';property='property';value='property'})

      .PARAMETER UpdateSource
      Provides the array of Arguments that needs to be merged with the existing arguments.

      .PARAMETER ExistingArguments
      Provides the list of arguments that needs to be updated.

      .PARAMETER ResolutionBehavior
      This parameter dictates the actions taken when a parameter in UpdateSource correspond to
      a parameter in ExistingArguments.

            'UpdateOnly'
                If the argument is matched, its properties' values are replaced with the ones provided.

            'UpdateAndAdd'
                If the argument is matched, its properties' values are replaced, otherwise it's appended.

            'ExactAndFinal'
                No matching is processed, the UpdateSource should replace entirely the ExistingArguments.
                UpdateSource is returned without processing.

            'RemoveIfPresent'
                If the argument is matched, it will be removed from the returned list.

            'RemoveIfExact'
                If each properties of the UpdateSource argument matches properties of an argument of the
                ExistingArguments list, it will be removed from the returned list.

            'ErrorArgumentExists'
                If the argument is matched, it will throw an error.

            'ErrorArgumentIfExact'
                If each properties of the UpdateSource argument matches properties of an argument of the
                ExistingArguments list, it will throw an error.

            'ReturnIfPresent'
                Only if the argument is matched, it will be returned in the the returned list.

            'ReturnIfExact'
                If each properties of the UpdateSource argument matches properties of an argument of the
                ExistingArguments list, it will be returned in the the returned list.

      .PARAMETER MatchArgumentOn
      Properties to compare the Argument on, if they exists on the object.

      .PARAMETER ArgumentsDefinitionFile
      Json file defining a list of parser for the tokens.
      
      #>
    [cmdletBinding()]
    [OutputType('PScustomObject[]')]
    Param(

        [Parameter(
            Mandatory
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
            )]
        [PSCustomObject[]]
        $UpdateSource,

        [Parameter(
            Mandatory
            ,ValueFromPipelineByPropertyName
            )]
        [System.Collections.Generic.List[PSCustomObject]]
        $ExistingArguments,

        [Parameter(
            ValueFromPipelineByPropertyName
            )]
        [ValidateSet(
            'UpdateOnly',
            'UpdateAndAdd',
            'ExactAndFinal',
            'RemoveIfPresent',
            'RemoveIfExact',
            'ErrorArgumentExists',
            'ErrorArgumentIfExact',
            'ReturnIfPresent',
            'ReturnIfExact'
            )]
        [string]
        $ResolutionBehavior = 'UpdateAndAdd',

        [Parameter(
            ValueFromPipelineByPropertyName
            )]
        [string[]]
        $MatchArgumentOn = @('typename','property','key'),

        [Parameter(
            ValueFromPipelineByPropertyName
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
        $ArgumentsDefinition = Get-Content -Raw -Path $ArgumentsDefinitionFile | ConvertFrom-Json -ErrorAction Stop
    }

    Process {
        if ($ResolutionBehavior -eq 'ExactAndFinal') {
            Write-Output -InputObject $UpdateSource
            return
        }
        $ListFoundArguments = @()
        foreach ($Argument in $UpdateSource) {
            #search argument in Existing Args
                #if Type Match
                    #if CompareObject $argument $MatchArg -property $MatchArgumentOn
                    #Get $MatchArg index in $ExistingArgs
                    #if ResolutionBehavior -eq 'Update.*'
                        #Replace $ExistingArgs[$index] with $Argument
                    #elseif ResolutionBehavior -eq 'Remove'
                        #Pop $ExistingArgs[$index]
                    #elseif ResolutionBehavior -eq 'ErrorArgumentExists'
                        #Throw Argument Exists
                    #elseif ResolutionBehavior -eq 'ErrorArgumentIsExactly'
                        #if compare-object for all props returns null, throw

            $Definition = $ArgumentsDefinition |
                            Where-Object { $_.typeName -eq $Argument.PSTypeNames[0] } |
                            Select-Object -First 1

            #If no command override but defined and config, use config properties to match Object
            if(!$PSBoundParameters.ContainsKey('MatchArgumentOn') -and 
                $Definition.MatchArgumentOn
                ) {
                $MatchArgumentOn = $Definition.MatchArgumentOn
            } # Otherwise, use command defaults (property,key)
            $AllArgumentProperties = @()
            $AllArgumentProperties += $Definition.properties

            if($Definition.next_token_as) {
                $AllArgumentProperties += $Definition.next_token_as
            }

            if ($MatchArgumentOn -contains 'typename') {
                $PreFilteredArguments = $ExistingArguments | Where-Object { $_.PSTypeNames[0] -eq $Argument.PSTypeNames[0] }
            }
            else {
                $PreFilteredArguments = $ExistingArguments
            }
            $ArgumentFound = $false
            foreach ($ArgumentMatchingByType in $PreFilteredArguments) {
                $matchOn = $AllArgumentProperties | Where-Object {$_ -in $MatchArgumentOn}
                if(!(Compare-Object -ReferenceObject $Argument -DifferenceObject $ArgumentMatchingByType -Property $matchOn)) {
                    $ArgumentFound = $true
                    $index = $ExistingArguments.IndexOf($ArgumentMatchingByType)
                    Switch -Regex ($ResolutionBehavior) {
                        "^Update.*" { $ExistingArguments[$index] = $Argument}
                        "^RemoveIfPresent$"  { $ExistingArguments.RemoveAt($index) }
                        "^RemoveIfExact$"  { 
                            if(!(Compare-Object -ReferenceObject $Argument -DifferenceObject $ArgumentMatchingByType -Property $AllArgumentProperties)) {
                                Write-Verbose -Message ('Removing The Argument {0} as they match exactly' -f $index)
                                $ExistingArguments.RemoveAt($index)
                            }
                            else {
                                Write-Verbose "The Arguments values don't match exactly."
                            }
                        }

                        "^ErrorArgumentExists$" { Throw 'Error Argument Exists' }
                        "^ErrorArgumentIsExactly$" {
                            if(!(Compare-Object -ReferenceObject $Argument -DifferenceObject $ArgumentMatchingByType -Property $AllArgumentProperties)) {
                                Throw "Error The Arguments match exactly"
                            }
                        }
                        '^ReturnIfPresent$' {
                            $ListFoundArguments += $Argument
                        }
                        '^ReturnIfExact$' {
                            if(!(Compare-Object -ReferenceObject $Argument -DifferenceObject $ArgumentMatchingByType -Property $AllArgumentProperties)) {
                                $ListFoundArguments += $Argument
                            }
                        }
                    }
                }
            }
            if(!$ArgumentFound -and $ResolutionBehavior -eq 'UpdateAndAdd') {
                $ExistingArguments += $Argument
            }
        }
        if ($ResolutionBehavior -match '^Return') {
            Write-Output -InputObject $ListFoundArguments
        }
        else {
            Write-Output -InputObject $ExistingArguments
        }
    }

}