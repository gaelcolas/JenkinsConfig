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

  Context 'Unit Test Quality' {
    $PrivateFunctions = Get-ChildItem -Path "$modulePath\Private\*.ps1"
    $PublicFunctions =  Get-ChildItem -Path "$modulePath\Public\*.ps1"

    Foreach ($PrivateFunction in $PrivateFunctions) {
        $functionName = $PrivateFunction.BaseName
        It "$functionName has a unit test" {
            Test-Path "$modulePath\tests\Unit\$functionName.tests.ps1" | Should be true
        }
    }

    Foreach ($PublicFunction in $PublicFunctions) {
        $functionName = $PublicFunction.BaseName
        It "$functionName has a unit test" {
            Test-Path "$modulePath\tests\Unit\$functionName.tests.ps1" | Should be true
        }
    }

  }
}