function New-GroovyCommand {
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
        DefaultParameterSetName='ByFolder'
    )]
    [OutputType('TypeName')]
    Param(

        [Parameter(
            Mandatory
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
            ,ParameterSetName='ByFile'
            )]
        [io.FileInfo[]]
        $GroovyFile,

        [Parameter(
            ValueFromPipelineByPropertyName
            ,ParameterSetName='ByFolder'
            )]
        [io.DirectoryInfo]
        $GroovyFolder = ([io.DirectoryInfo]$PSScriptRoot),

        [Parameter(
            ValueFromPipelineByPropertyName
            )]
        [switch]
        $asText

    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'ByFolder') {
            $GroovyFile = Get-ChildItem -Path $GroovyFolder -Include *.groovy -Recurse
        }
    }

    Process {

        foreach ($Groovy in $GroovyFile) {
            $GroovyScript = Get-Content -Raw $Groovy
            #Groovy.BaseName
            $MatchingGroups = [regex]::Match($GroovyScript,'\s*\/\*(?<script>[\w\W]*?)\*\/(?<groovy>[\W\w]*)')
            $ScriptString = $MatchingGroups.groups['script'].value.Trim()
            $groovyToProcess = $MatchingGroups.groups['groovy'].value.Trim()
            $Function = New-Item -Path function: -Name test -Force -Value ([scriptblock]::Create($ScriptString)) #[scriptblock]::Create("function Test {  $ScriptString }")
            $FunctionMeta = New-Object -TypeName System.Management.Automation.CommandMetaData -ArgumentList $Function
            $MetaData = New-Object -TypeName System.Management.Automation.CommandMetaData -ArgumentList (Get-Command -Name Invoke-GroovyScript)
            $null = $MetaData.Parameters.Remove('GroovyScript')
            
            $ParamsAdded = @()
            foreach ($ParamToAdd in $FunctionMeta.Parameters.Keys) {
                $ParamsAdded += $ParamToAdd
                $MetaData.Parameters[$ParamToAdd] = $FunctionMeta.Parameters[$ParamToAdd]
            }
            $Metadata.Parameters.Add('GetProcessedGroovyOnly',[System.Management.Automation.ParameterMetadata]::new('GetProcessedGroovyOnly',[switch]))

            $FunctionContent = [System.Management.Automation.ProxyCommand]::Create($MetaData)

            $groovyPSScriptAst = [scriptblock]::Create($ScriptString).ast

            $blockToInsert = $ScriptString.Substring($groovyPSScriptAst.ParamBlock.Extent.EndOffset)

            $blockToInsert += @"
            `r`n
            `$groovyToProcess = @'
$groovyToProcess
'@
            `$ParamsToRemove = @('$($ParamsAdded -join "','")')

"@
            $blockToInsert += {
                # Process $groovyToProcess:
                # regex replace with variable value
                $ProcessedFunctionContent = [regex]::Replace(
                    $groovyToProcess,
                    '<%=(?<variableName>.*?)%>',{
                                param($match)
                                $expr = $match.groups['variableName'].value
                                $res = Get-Variable -Name $match.groups['variableName'] -ValueOnly
                                Write-Debug -Message ("Replacing '{0}' with '{1}'" -f $expr, $res)
                                $res
                            },
                     @('IgnoreCase')
                )

                $groovyScript = $ProcessedFunctionContent
                if ($PSBoundParameters.ContainsKey('GetProcessedGroovyOnly')) {
                    return $groovyScript
                    break
                }
                $PSBoundParameters.Add('GroovyScript',$GroovyScript)
                $ParamsToRemove | ForEach-Object { $null = $PSBoundParameters.Remove($_) }
                
            }.ToString()
            
            $FunctionAST = [scriptblock]::Create($FunctionContent).Ast
            $Begin = $FunctionAST.BeginBlock.Statements
            $InsertOffset = $Begin[0].Extent.StartOffset

            $FunctionCore = $FunctionContent.Insert($InsertOffset,$blockToInsert)

            if ($asText) {
                return ("function $($Groovy.BaseName) {`r`n $FunctionCore `r`n}")
            }
            else {
                #New-Item -Path function: -Name $Groovy.BaseName -Value $FunctionCore -Force
                Write-Output @{FunctionName = $Groovy.BaseName;FunctionCore = $FunctionCore}
            }
        }
    }

}