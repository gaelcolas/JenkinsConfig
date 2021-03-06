function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $InstallKey
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    <#
    $returnValue = @{
    Ensure = [System.String]
    InstallKey = [System.String]
    Port = [System.UInt16]
    RunSetupWizard = [System.Boolean]
    AdminCredential = [System.Management.Automation.PSCredential]
    RunServiceAs = [System.Management.Automation.PSCredential]
    }

    $returnValue
    #>
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $InstallKey,

        [System.UInt16]
        $Port,

        [System.Boolean]
        $RunSetupWizard,

        [System.Management.Automation.PSCredential]
        $AdminCredential,

        [System.Management.Automation.PSCredential]
        $RunServiceAs
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
        [parameter(Mandatory = $true)]
        [System.String]
        $InstallKey,

        [System.UInt16]
        $Port,

        [System.Boolean]
        $RunSetupWizard,

        [System.Management.Automation.PSCredential]
        $AdminCredential,

        [System.Management.Automation.PSCredential]
        $RunServiceAs
    )

    #Write-Verbose "Use this cmdlet to deliver information about command processing."

    #Write-Debug "Use this cmdlet to write debug information while troubleshooting."


    <#
    $result = [System.Boolean]
    
    $result
    #>
}


Export-ModuleMember -Function *-TargetResource

