function Invoke-JenkinsCommand {
    <#
      .SYNOPSIS
      Describe the function here
      .DESCRIPTION
      Describe the function in more detail
      .EXAMPLE
      Give an example of how to use it
      .EXAMPLE
      Give another example of how to use it
      .PARAMETER Param1
      The param1
      .PARAMETER param2
      The second param
      #>
    [cmdletBinding(
            SupportsShouldProcess=$true,
            ConfirmImpact='Low'
            )]
    [OutputType('TypeName',ParameterSetName='ParamSet')]
    Param(
        [parameter()]
        [type]
        $param,

        [Parameter(
            Mandatory
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
            ,ParameterSetName='ParamSet'
            )]
        [ValidateLength(1,10)]
        [PSTypeName('MyCustomTypeName')]
        [type2]
        $param2
    )

    begin {
        
    }

    Process {
        if ($pscmdlet.ShouldProcess($Param)) {
            Write-Output  ([PSCustomObject]@{
                PSTypeName='TypeName'
            })
        }
    }

}