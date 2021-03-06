﻿function Set-JenkinsSvcParameter {
    <#
      .SYNOPSIS
      Updates the Jenkins.xml Arguments node with given tokens.

      .DESCRIPTION
      Merge the Java options or Jar Arguments of the Jenkins.xml file based on a list of tokens, following the pattern:
      Java [Options] -jar Jenkins.jar [arguments]
      
      The Resolution behavior allows you to finely control how the merge is processed. 

      .EXAMPLE
      $Params = @{
        JenkinsArgumentTokens= '--httpport=443'
        ResolutionBehavior = 'UpdateAndAdd'
        JenkinsXMLPath = 'C:\Program Files (x86)\Jenkins\Jenkins.xml'
      }
      Set-JenkinsSvcParameter @Params

      .PARAMETER JenkinsArgumentTokens
      A list of Arguments to be parsed and merged with the existing values.

      .PARAMETER JavaOptionOrJarArgument
      A selector that allows you to set either part of the Java arguments such as:
      Java [options] -jar jenkins.jar [arguments]

      .PARAMETER ResolutionBehavior
      Merge behavior between the existing list of arguments and the provided update.

      .PARAMETER JenkinsXMLPath
      Jenkins.xml file defining the Service configuration.

      .PARAMETER ArgumentsDefinitionFile
      Definition file in Json that describes how the Tokens needs to be parsed, and in this case, how the parsed tokens
      can be converted back to tokens before joining them in a string, in the relevant node of the XML configuration.

      #>
    [cmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType('void')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
            )]
        [string[]]
        $JenkinsArgumentTokens,
        
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
            )]
        [ValidateSet('JavaOption','JarArgument')]
        $JavaOptionOrJarArgument,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
            )]
        [ValidateSet(
            'UpdateOnly',
            'UpdateAndAdd',
            'ExactAndFinal',
            'RemoveIfPresent',
            'RemoveIfExact'
            )]
        [string]
        $ResolutionBehavior,

        [Parameter(
            ValueFromPipelineByPropertyName
            )]
        [IO.FileInfo]
        $JenkinsXMLPath = [IO.FileInfo]::new('C:/Program Files (x86)/Jenkins/Jenkins.xml'),

        [Parameter(
            ValueFromPipelineByPropertyName
            )]
        [io.FileInfo]
        $ArgumentsDefinitionFile = $null
    )

    Process {

        switch ($JavaOptionOrJarArgument) {
            'JavaOption'  { 
                $ArgumentsProperty = 'Options'   
                $DefaultArgumentDefinitionFile = "$PSScriptRoot/../config/JavaOptions.definition.json"
            }
            'JarArgument' { 
                $ArgumentsProperty = 'Arguments' 
                $DefaultArgumentDefinitionFile = "$PSScriptRoot/../config/JenkinsArguments.definition.json"
            }
            Default {
                Throw ('JavaOptionOrJarArgument value {0} not recognized' -f $JavaOptionOrJarArgument)
            }
        }

        if ($PSBoundParameters.ContainsKey('ArgumentsDefinitionFile') -or !$ArgumentsDefinitionFile) {
            $ArgumentsDefinitionFile = $DefaultArgumentDefinitionFile
        }
        Write-Verbose -Message ('Using Argument Definition File {0}' -f $ArgumentsDefinitionFile)
        Write-Verbose -Message 'Getting Jenkins Svc Config'
        $JenkinsConfig = Get-jenkinsSvcConfig -JenkinsXMLPath $JenkinsXMLPath -ErrorAction Stop
        Write-Verbose -Message ('Transforming Jenkins Config {0} Tokens into Arguments using: {1}' -f $ArgumentsProperty,$ArgumentsDefinitionFile)
        $CurrentArguments = Get-ArgumentFromToken -ArgumentToken $JenkinsConfig.Service.arguments.($ArgumentsProperty) -ArgumentsDefinitionFile $ArgumentsDefinitionFile -Verbose
        Write-Verbose -Message 'Transforming provided Tokens into arguments'
        $ArgumentsToUpdate = Get-ArgumentFromToken -ArgumentToken $JenkinsArgumentTokens -ArgumentsDefinitionFile $ArgumentsDefinitionFile
        Write-Verbose -Message ('Merging Arguments based on the behavior sepecified: {0}' -f $ResolutionBehavior)
        $NewJenkinsArguments = Merge-Argument -UpdateSource $ArgumentsToUpdate -ExistingArguments $CurrentArguments -ResolutionBehavior $ResolutionBehavior -ArgumentsDefinitionFile $ArgumentsDefinitionFile
        $JenkinsConfig.service.arguments.($ArgumentsProperty) = Get-TokensFromArgument -ArgumentList $NewJenkinsArguments -ArgumentsDefinitionFile $ArgumentsDefinitionFile

        if ($PSCmdlet.ShouldProcess($JenkinsXMLPath.FullName)) {
            Write-Verbose -Message 'Writing the updated values to the file.'
            Set-JenkinsSvcConfig -ConfigurationObject $JenkinsConfig -JenkinsXMLPath $JenkinsXMLPath
        }
    }
}