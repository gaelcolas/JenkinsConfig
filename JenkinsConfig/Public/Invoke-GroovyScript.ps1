#Invoke-GroovyScript is an helper function, proxying Invoke-JenkinsCommand
#the Command is always @('groovy','=') and the groovyScript is passed as STDIN (aka InputObject to Invoke-JenkinsCommand).

#Just in case the order of dot sourcing has not imported the function to be proxied yet
if (!(Get-Command Invoke-JenkinsCommand -ErrorAction SilentlyContinue)) {
    . "$PSScriptRoot/Invoke-JenkinsCommand.ps1"
}
$MetaData = New-Object -TypeName System.Management.Automation.CommandMetaData -ArgumentList (Get-Command  -Name Invoke-JenkinsCommand)
$InputObjectParam = $MetaData.Parameters.InputObject
$InputObjectParam.Name = 'GroovyScript'

$GroovyParameter = [System.Management.Automation.ParameterMetadata]::new($InputObjectParam)
$GroovyParameter.ParameterSets.__AllParameterSets.IsMandatory = $True
$GroovyParameter.Attributes.Add([System.Management.Automation.ValidateNotNullAttribute]::new())

$MetaData.Parameters.Add('GroovyScript',$GroovyParameter)

$null = $MetaData.Parameters.Remove('InputObject')
$null = $MetaData.Parameters.Remove('Command')
$null = $MetaData.Parameters.Remove('CommandArgument')

$blockToInsert = {
    $PSBoundParameters.add('Command',@('groovy','='))
    $PSBoundParameters.add('InputObject',$GroovyScript)
    $null = $PSBoundParameters.Remove('GroovyScript')
    }.ToString()

$FunctionContent = [System.Management.Automation.ProxyCommand]::Create($MetaData)

$FunctionAST = [scriptblock]::Create($FunctionContent).Ast
$Begin = $FunctionAST.BeginBlock.Statements
$InsertOffset = $Begin[0].Extent.StartOffset

$FunctionCore = $FunctionContent.Insert($InsertOffset,$blockToInsert)

$null = New-Item -Path Function: -Name Invoke-GroovyScript -Value $FunctionCore
