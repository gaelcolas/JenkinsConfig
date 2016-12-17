function Get-ArgumentFromToken {
    <#
      .SYNOPSIS
      Returns a list of PSObjects representing logical arguments based on a list of Tokens.
      The processing is based on a definition file 
      (default being $here\config\JavaOptions.definition.json).

      .DESCRIPTION
      This command attempts to read a tokenized Command
      and extract each option into a PSobject, based on a parser definition file
      written in JSON.
      The goal is to identify the parameters and extract its information consistently
      in order to allow for identification and comparison of properties, key, values.
      This as beend designed to accomodate Java options, as they are not standardized. 
      
      .EXAMPLE
      Get-ArgumentFromToken -ArgumentsTokens '-classpath','this.jar','-property:key=value'
      #output: returns 2 objects similar to those below
      #@{property='classpath';classpath='this.jar'}
      #@{dashes='-';key='key';value='value';separator=':'}
      
      .EXAMPLE
      Get-ArgumentFromToken -ArgumentToken '--key:value','--httport:8080'`
                     -ArgumentsDefinitionFile C:\JenkinsArguments.jsonb
      
      .PARAMETER ArgumentToken
      List of tokenized command arguments (array of string) that can be parsed by a 
      given Argument Definition file.
      
      .PARAMETER ArgumentsDefinitionFile
      Json file defining a list of parser for the tokens.
      
      The parser entries are short-listed by the 'selector' property (Sellecting all that are a match)
      Then the first 'parser' property's regex that successfully match the token will be used, and its
      groups will parse each 'properties' of the parser object (by groupName or group index) to
      be then added into a PSObject as a noteproperty.

      .NOTES
      A java command looking like 
        java [ options ] class [ arguments ]
      may have many options, with different property/key/values.
      Some are separated by space (second token, i.e. -cp your\class\path),
      others per delimiters: -property:key=value,
      and each have their own peculiar standard.
      #>
    [cmdletBinding()]
    [OutputType('PSCustomObject')]
    Param(
        [Parameter(
            Mandatory
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
            )]
        [validateNotNull()]
        [String[]]
        $ArgumentToken,

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
        $GrabbingTokenForPreviousOption = $false
        $OptionStack = $null
        foreach ($Token in $ArgumentToken) {
           #for Each token
            #if we're not grabbing current Token as property for previous Java Option
            #Select each JavaOption parser where the token match the selector
            #for the first matching parser,
            #use it to extract properties and create object from it
            if ($GrabbingTokenForPreviousOption) {
                Write-Debug -Message ('Adding property {0} with value {1}' -f $optionStack.next_token_as,$Token)
                $OptionStack.Object | Add-member -memberType NoteProperty -name $optionStack.next_token_as -value $Token
                $GrabbingTokenForPreviousOption = $false
                Write-Output -InputObject $OptionStack.Object
                Write-Verbose -Message ('Sending object of type {0} to output stream' -f $OptionStack.Object.PSTypeNames[0])
                $OptionStack = $null
            }
            else {
                $PossibleParsers = @()
                $PossibleParsers += $ArgumentsDefinition | Where-Object {
                                        Write-Debug -Message ('Trying selection {0}' -f $_.selector)
                                        $isMatch = $Token -cmatch $_.selector
                                        if ($isMatch)  { Write-Debug -Message '... Match' }
                                        return $isMatch
                                    }
                #region Iterate Through Selected Parsers and attempt grabbing properties
                $result = $null
                $isFound = $false
                $ParserIterator = $PossibleParsers.GetEnumerator()
                while (!$isFound -and $ParserIterator.MoveNext()) {
                    $CurrentOptionDefinition = $ParserIterator.Current
                    Write-Verbose -Message ('Attempting to parse using parser {0}' -f $CurrentOptionDefinition.name)
                    $result = [regex]::Match($Token,$CurrentOptionDefinition.Parser)
                    if ($result.Success) {
                        Write-Verbose -Message "`tParsing success."
                        $isFound = $true
                    }
                }
                if (!$result.Success) {
                    Throw "Could not parse the given token: $token"
                }
                $JavaOptionProperties = @{}
                $value = $null
                foreach ($property in $CurrentOptionDefinition.properties) {
                    if (!($value = $result.Groups[$property].value)) { #Try resolution per GroupName
                        #else use resolution matching Groups per position of property name
                        $index = $CurrentOptionDefinition.properties.indexOf($property)
                        Write-Debug -Message ('Matching Propety {0} with index {1}' -f $property,$index)
                        $value = $result.Groups[$index+1].value
                    }
                    
                    Write-Debug -Message ("Adding property {0} with value: {1}" -f $property,$value)
                    $JavaOptionProperties.Add($property,$value)
                }
                $JavaOption = New-Object PSCustomObject -Property $JavaOptionProperties |
                                Add-Member -TypeName $CurrentOptionDefinition.TypeName -PassThru
                if ($CurrentOptionDefinition.next_token_as) {
                    Write-Verbose -Message ('Next Token is the value for property {0}.' -f $CurrentOptionDefinition.next_token_as)
                    $OptionStack = @{Object = $JavaOption; next_token_as = $CurrentOptionDefinition.next_token_as }
                    $GrabbingTokenForPreviousOption = $true
                }
                else {
                    Write-Verbose -Message ('Sending object of type {0} to output stream' -f $JavaOption.PSTypeNames[0])
                    Write-Output -InputObject $JavaOption
                }
                #endregion

            }
        }
    }

}