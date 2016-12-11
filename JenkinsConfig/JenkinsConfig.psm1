$here = $PSScriptRoot


Get-ChildItem -Path "$here\Private" | ForEach-Object {
    . $_.FullName
} 

Get-ChildItem -Path "$here\Public" | ForEach-Object {
    . $_.FullName
    Export-ModuleMember -Function $_.BaseName
} 