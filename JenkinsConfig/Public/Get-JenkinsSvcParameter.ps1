function Get-JenkinsSvcParameter {
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
    [cmdletBinding(DefaultParameterSetName='ByServiceName')]
    [OutputType('void')]
    Param(    
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
            )]
        [ValidateSet('JavaOption','JarArgument')]
        $JavaOptionOrJarArgument,

        [AllowNull()]
        [Parameter(
            ValueFromPipelineByPropertyName
            ,ParameterSetName='ByJenkinsXmlFile'
            )]
        [IO.FileInfo]
        $JenkinsXMLPath = $null,

        [ValidateScript({$null -eq $_ -or (Get-service -Name $_)})]
        [Parameter(
            ValueFromPipelineByPropertyName
            ,ParameterSetName='ByServiceName'
            )]
        [String]
        $ServiceName = $null,

        [Parameter(
            ValueFromPipelineByPropertyName
            )]
        [io.FileInfo]
        $ArgumentsDefinitionFile = $null
    )

    Process {
        if ($PSCmdlet.ParameterSetName -eq 'ByServiceName') {
            $JenkinsHome = Get-JenkinsHomeFromSvcName -ServiceId $serviceName
            $JenkinsXMLPath = Join-Path  -Path $JenkinsHome -ChildPath 'Jenkins.xml' -Resolve -ErrorAction Stop
        }

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
       
       Write-Output -InputObject $CurrentArguments
    }
}