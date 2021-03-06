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
    Import-module -Name JenkinsConfig
    $JenkinsSvcArgs = Get-JenkinsSvcArgumentObject -ServiceName $ServiceName
    $JavaArguments = $JenkinsSvcArgs.Arguments

    Write-output -inputObject (@{
        Tokens = $JavaArguments
        RunName = $RunName
        ServiceName = $ServiceName
    })
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet("UpdateOnly","UpdateAndAdd","ExactAndFinal","RemoveIfPresent","RemoveIfExact","ErrorArgumentExists","ErrorArgumentIfExact")]
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
        $ServiceName,

        [System.Boolean]
        $RestartService
    )
    Import-module -Name JenkinsConfig
    Write-verbose 'Merging with the Tokens passed as arguments'
    $Params = @{
        JenkinsArgumentTokens   = $Tokens
        JavaOptionOrJarArgument = 'JarArgument'
        ResolutionBehavior      = $ResolutionMode
    }
    Set-JenkinsSvcParameter @Params -verbose

    if ($RestartService) {
        Restart-Service -Name $ServiceName -Force
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [ValidateSet("UpdateOnly","UpdateAndAdd","ExactAndFinal","RemoveIfPresent","RemoveIfExact","ErrorArgumentExists","ErrorArgumentIfExact")]
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
        $ServiceName,

        [System.Boolean]
        $RestartService
    )

    Import-module -Name JenkinsConfig
    Write-Verbose 'Retrieving Current configuration.'    
    $JenkinsSvcArgsObjects = Get-JenkinsSvcParameter -JavaOptionOrJarArgument JarArgument -ServiceName $ServiceName
    $ArgumentFromTokenParams = @{
        ArgumentToken           = $Tokens
        ArgumentsDefinitionFile = "$PSScriptRoot\..\..\config\JenkinsArguments.definition.json"
    }

    $ArgumentFromTokens = Get-ArgumentFromToken @ArgumentFromTokenParams
    $MergeParams = @{
         UpdateSource      = $ArgumentFromTokens 
         ExistingArguments = $JenkinsSvcArgsObjects
         ArgumentsDefinitionFile = "$PSScriptRoot\..\..\config\JenkinsArguments.definition.json"
    }
    $ArgumentExacts   = Merge-Argument @MergeParams -ResolutionBehavior ReturnIfExact
    $ArgumentPresents = Merge-Argument @MergeParams -ResolutionBehavior ReturnIfPresent

    switch ($ResolutionMode) {
        {$_ -eq 'ExactAndFinal'} {

            $ExistingTokens = Get-TokensFromArgument -ArgumentList $JenkinsSvcArgsObjects -ArgumentsDefinitionFile "$PSScriptRoot\..\..\config\JenkinsArguments.definition.json"
            $comparison = Compare-Object -ReferenceObject $ExistingTokens -DifferenceObject $Tokens

            if ($comparison) { 
                Write-Verbose -Message ('The current Tokens ({0}) do not match exactly the provided ones ({1}).' -f 
                    ($ExistingTokens -join ','),$Tokens)

                return $false
            }
            else {
                return $true
            }
        }
        {$_ -in @('UpdateOnly','UpdateAndAdd')} {
            if($ArgumentFromTokens.count -eq $ArgumentExacts.Count) { #as many exact match as input = no update needed
                return $true
            }
            elseif($_ -eq 'UpdateOnly' -and ($ArgumentPresents.Count -eq $ArgumentExacts.Count)) { 
                #as many presents than exacts (ignoring absents in updateOnly)
                return $true
            }
            else {
                return $false
            }
        
        }

        {$_ -in @('RemoveIfPresent','ErrorArgumentExists') } {
            if($ArgumentPresents) {
                return $false
            }
            else {
                return $true
            }
        }

        {$_ -in @('RemoveIfExact','ErrorArgumentIfExact')} {
            if($ArgumentExacts) {
                return $false
            }
            else {
                return $true
            }
        }

    }
}



