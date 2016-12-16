$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$modulePath = "$here\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf

Describe "$moduleName" {

  Context 'General context'   {

    It 'imports without errors' {
        { Import-Module -Name $modulePath -Force } | Should Not Throw
        Get-Module $moduleName | Should Not BeNullOrEmpty
    }

    It 'Removes without error' {
      { Remove-Module -Name $moduleName } | Should not Throw
      Get-Module $moduleName | Should beNullOrEmpty
    }

  }

    #$PrivateFunctions = Get-ChildItem -Path "$modulePath\Private\*.ps1"
    #$PublicFunctions =  Get-ChildItem -Path "$modulePath\Public\*.ps1"
    $allModuleFunctions = @()
    $allModuleFunctions += Get-ChildItem -Path "$modulePath\Private\*.ps1"
    $allModuleFunctions += Get-ChildItem -Path "$modulePath\Public\*.ps1"

    if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
        $scriptAnalyzerRules = Get-ScriptAnalyzerRule
    }
    else {
        Write-Warning "ScriptAnalyzer not found!"
    }

    foreach ($function in $allModuleFunctions) {
        Context "Quality for $($function.BaseName)" {
            It "$($function.BaseName) has a unit test" {
                Test-Path "$modulePath\tests\Unit\$($function.BaseName).tests.ps1" | Should be true
            }
        if ($scriptAnalyzerRules) {
                It "Script Analyzer for $($function.BaseName)" {
                    forEach ($scriptAnalyzerRule in $scriptAnalyzerRules) {
                        (Invoke-ScriptAnalyzer -Path $function.FullName -IncludeRule $scriptAnalyzerRule).count | Should Be 0
                    }
                }
            }
        }
    }
}