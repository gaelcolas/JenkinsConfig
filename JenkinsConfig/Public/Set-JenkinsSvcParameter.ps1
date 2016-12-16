function Set-JenkinsSvcParameter {
    <#
      .SYNOPSIS
      Describe the function here

      .DESCRIPTION
      Describe the function in more detail

      .EXAMPLE
      $Params = @{
        JenkinsArgumentTokens= '--httpport=443'
        ResolutionBehavior = 'UpdateAndAdd'
        JenkinsXMLPath = 'C:\Program Files (x86)\Jenkins\Jenkins.xml'
      }
      Set-JenkinsJavaArgument @Params

      .EXAMPLE
      Give another example of how to use it

      .PARAMETER Param1
      The param1

      .PARAMETER param2
      The second param
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

        if ($PSBoundParameters.ContainsKey('ArgumentsDefinitionFile')) {
            $ArgumentsDefinitionFile = $DefaultArgumentDefinitionFile
        }

        $JenkinsConfig = Get-jenkinsSvcConfig -JenkinsXMLPath $JenkinsXMLPath -ErrorAction Stop
        $CurrentArguments = Get-ArgumentsFromToken -ArgumentsTokens $JenkinsConfig.Service.arguments.($ArgumentsProperty) -ArgumentsDefinitionFile $ArgumentsDefinitionFile
        $ArgumentsToUpdate = Get-ArgumentsFromToken -ArgumentsTokens $JenkinsArgumentTokens -ArgumentsDefinitionFile $ArgumentsDefinitionFile
        $NewJenkinsArguments = Merge-Argument -UpdateSource $ArgumentsToUpdate -ExistingArguments $CurrentArguments -ResolutionBehavior $ResolutionBehavior -ArgumentsDefinitionFile $ArgumentsDefinitionFile
        $JenkinsConfig.service.arguments.($ArgumentsProperty) = Get-TokensFromArgument -ArgumentList $NewJenkinsArguments -ArgumentsDefinitionFile $ArgumentsDefinitionFile

        if ($PSCmdlet.ShouldProcess($JenkinsXMLPath.FullName)) {
            Set-JenkinsSvcConfig -ConfigurationObject $JenkinsConfig -JenkinsXMLPath $JenkinsXMLPath
        }
    }
}