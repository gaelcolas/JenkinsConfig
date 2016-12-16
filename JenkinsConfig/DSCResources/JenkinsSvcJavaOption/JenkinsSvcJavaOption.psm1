function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String[]]
        $Tokens,

        [parameter(Mandatory = $true)]
        [System.String]
        $RunName,

        [parameter(Mandatory = $true)]
        [System.String]
        $ServiceName
    )

    
    $JavaOptionsObject = Get-JavaCommandObject -ServiceName $ServiceName
    $JavaArguments = 

    Write-output -inputObject (@{
        Tokens = $JavaOptionsObject
        RunName = $RunName
        ServiceName = $ServiceName
    })

}

function Get-JavaCommandObject {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $ServiceName
    )

    $JenkinsHome = Get-JenkinsHomeFromSvcName -ServiceName $ServiceName
    Write-Verbose -Message ('Jenkins Home Resolved to {0}' -f $JenkinsHome)

    if (!($JenkinsXMLPath = [io.fileInfo](Join-Path -sourcePath $JenkinsHome -ChildPath Jenkins.xml)) -or
        !$JenkinsXMLPath.Exists) {
        Throw ('Could not resolve path {0}\Jenkins.xml' -f $JenkinsHome)
    }
    Write-Output -inputObject (Get-JenkinsSvcArgumentObject -JenkinsXMLPath $JenkinsXMLPath)
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("UpdateOnly","UpdateAndAdd","ExactAndFinal","RemoveIfPresent","RemoveIfExact","ErrorArgumentExists","ErrorArgumentIfExact","ReturnIfPresent","ReturnIfExact")]
        [System.String]
        $ResolutionMode,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Tokens,

        [parameter(Mandatory = $true)]
        [System.String]
        $RunName,

        [parameter(Mandatory = $true)]
        [System.String]
        $ServiceName
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."

    #Include this line if the resource requires a system reboot.
    #$global:DSCMachineStatus = 1


}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("UpdateOnly","UpdateAndAdd","ExactAndFinal","RemoveIfPresent","RemoveIfExact","ErrorArgumentExists","ErrorArgumentIfExact","ReturnIfPresent","ReturnIfExact")]
        [System.String]
        $ResolutionMode,

        [parameter(Mandatory = $true)]
        [System.String[]]
        $Tokens,

        [parameter(Mandatory = $true)]
        [System.String]
        $RunName,

        [parameter(Mandatory = $true)]
        [System.String]
        $ServiceName
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    <#
    $result = [System.Boolean]
    
    $result
    #>
}


Export-ModuleMember -Function *-TargetResource

