function Set-JenkinsJavaArgument {
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
        ConfirmImpact = 'Medium'
    )]
    [OutputType('void')]
    Param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
            )]
        [PSTypeName('Jenkins.config.JavaArguments')]
        [PSCustomObject]

        $JenkinsJavaArguments,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
            )]
        [ValidateSet('UpdateOnly','UpdateAndAdd','ExactAndFinal','Remove','ErrorIfPresent')]
        [string]
        $ResolutionMode,

        [Parameter(
            ValueFromPipelineByPropertyName
            )]
        [IO.FileInfo]
        $JenkinsXMLPath = [IO.FileInfo]::new('C:/Program Files (x86)/Jenkins/Jenkins.xml')
    )

    Process {
        $JenkinsXml = Get-JenkinsXml -JenkinsXMLPath $JenkinsXMLPath -ErrorAction Stop
        $JenkinsXml.service.arguments = Get-JavaCommandFromJavaCommandObject -JavaCommandObject $JenkinsJavaArguments

        if ($PSCmdlet.ShouldProcess($JenkinsXMLPath.FullName)) {
            $JenkinsXml.Save($JenkinsXMLPath.FullName)
        }
    }
}