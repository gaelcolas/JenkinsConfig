$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

Describe 'Get-ArgumentsFromTokens' {

  Context 'General context'   {

    It 'runs without errors' {
        { Get-ArgumentsFromTokens -ArgumentsTokens '-Option' } | Should Not Throw
    }

    It 'throws when JavaOptionToken is null' {
      { Get-ArgumentsFromTokens -ArgumentsTokens $null } | Should Throw
    }

  }

  Context 'Run list of tests to validate parsing' {
    $listOfTests = @(
            @{TestInput = '-client'; result = [PSCustomObject]@{PSTypeName='Java.Option.SingleKey';key='client';dashes='-'}}
            ,@{TestInput = '-server'; result = [PSCustomObject]@{PSTypeName='Java.Option.SingleKey';key='server';dashes='-'}}
            ,@{TestInput = '-agentpath:pathname'; result = [PSCustomObject]@{PSTypeName='Java.Option.KeyValue';property='agentpath';key='pathname';value='';separator=':';dashes='-'}}
            ,@{TestInput = '-agentpath:pathname=options1'; result = [PSCustomObject]@{PSTypeName='Java.Option.KeyValue';property='agentpath';key='pathname';value='options1';separator=':';dashes='-'}}
            ,@{TestInput = '-classpath','path\class.jar'; result = [PSCustomObject]@{PSTypeName='Java.Option.ClassPath';property='classpath';classpath='path\class.jar';}}
            ,@{TestInput = '-Dproperty=value'; result = [PSCustomObject]@{PSTypeName='Java.Option.DPropertyValue';property='property';dashes='-';'D'='D';value='value'};}
            ,@{TestInput = '-da:com.wombat.fruitbat...'; result = [PSCustomObject]@{PSTypeName='Java.Option.KeyValue';property='da';key='com.wombat.fruitbat...';separator=':';dashes='-'}}
    )
    
    foreach ($test in $listOfTests) {
        It "parses $($test.testInput) to $($test.result)" -Pending:(.{try{[bool]::Parse($test.pending)}catch{$false}}) {
            $propertiesToTest = $test.result | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
            $Result = Get-ArgumentsFromTokens -ArgumentsTokens $test.TestInput
            Compare-Object -ReferenceObject $test.result -DifferenceObject $result -Property $propertiesToTest | Should BeNullOrEmpty
            $Result.PSTypeNames | Should be $test.result.PSTypeNames
        }
    }
  }
}
