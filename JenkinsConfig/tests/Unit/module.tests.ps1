$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$modulePath = "$here\..\.."
$moduleName = Split-Path -Path $modulePath -Leaf


Describe 'General module control'   {

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
    Describe "Quality for $($function.BaseName)" -Tags 'QA','Release' {
        It "$($function.BaseName) has a unit test" {
            Test-Path "$modulePath\tests\Unit\$($function.BaseName).tests.ps1" | Should be true
        }
            
        if ($scriptAnalyzerRules) {
            It "Script Analyzer for $($function.BaseName)" {
                forEach ($scriptAnalyzerRule in $scriptAnalyzerRules) {
                    (Invoke-ScriptAnalyzer -Path $function.FullName -IncludeRule $scriptAnalyzerRule).count |
                         Should Be 0
                }
            }
        }
    }
    Describe "Help for $($function.BaseName)" -Tags 'AdvancedQA','Release','help' {
            $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
                ParseInput((Get-Content -raw $function.FullName), [ref]$null, [ref]$null)
                $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
                $ParsedFunction = $AbstractSyntaxTree.FindAll( $AstSearchDelegate,$true )   |
                                    ? Name -eq $function.BaseName
            $FunctionHelp = $ParsedFunction.GetHelpContent()

            It 'Has a SYNOPSIS' {
                $FunctionHelp.Synopsis | should not BeNullOrEmpty
            }

            It 'Has a Description, with length > 40' {
                $FunctionHelp.Description.Length | Should beGreaterThan 40
            }

            It 'Has at least 1 example' {
                $FunctionHelp.Examples.Count | Should beGreaterThan 0 
                $FunctionHelp.Examples[0] | Should match ([regex]::Escape($function.BaseName))
                $FunctionHelp.Examples[0].Length | Should BeGreaterThan ($function.BaseName.Length + 10)
            }

            $parameters = $ParsedFunction.Body.ParamBlock.Parameters.name.VariablePath | % {$_.ToString() }
            foreach ($parameter in $parameters) {
                It "Has help for Parameter: $parameter" {
                    $FunctionHelp.Parameters.($parameter.ToUpper())        | Should Not BeNullOrEmpty
                    $FunctionHelp.Parameters.($parameter.ToUpper()).Length | Should BeGreaterThan 25
                }
            }
    }
}

