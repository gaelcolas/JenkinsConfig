$here = $PSScriptRoot


Get-ChildItem -Path "$here\Private" | ForEach-Object {
    . $_.FullName
    Write-Verbose -Message ('Loading {0}' -f $_.BaseName)
}

Get-ChildItem -Path "$here\Public" | ForEach-Object {
    . $_.FullName
    Write-Verbose -Message ('Loading and exporting {0}' -f $_.BaseName)
    Export-ModuleMember -Function $_.BaseName
} 


. "$PSScriptRoot/groovy/New-GroovyCommand.ps1"
New-GroovyCommand -GroovyFolder "$PSScriptRoot/groovy" | % {
    New-Item -Path function: -Name $_.FunctionName -Value $_.FunctionCore -Force
    Export-ModuleMember -Function $_.FunctionName
}