$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

Describe 'Get-ArgumentsFromTokens' {

  Context 'General context'   {

    It 'runs without errors' {
        { Get-ArgumentFromToken -ArgumentsTokens '-Option' } | Should Not Throw
    }

    It 'throws when JavaOptionToken is null' {
      { Get-ArgumentFromToken -ArgumentsTokens $null } | Should Throw
    }

  }

  #TODO: Add test for -Xmx256m,-Xms256m
  #TODO: Add test for -Xrunjdwp:transport=dt_socket,server=y,address=8000
  Context 'Run list of tests to validate parsing' {
    $listOfTests = @(
            @{TestInput = '-client'; result = [PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='client';}}
            ,@{TestInput = '-server'; result = [PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='server';}}
            ,@{TestInput = '-agentpath:pathname'; result = [PSCustomObject]@{PSTypeName='Java.Option.KeyValue';property='agentpath';key='pathname';value='';separator=':';}}
            ,@{TestInput = '-agentpath:pathname=options1'; result = [PSCustomObject]@{PSTypeName='Java.Option.KeyValue';property='agentpath';key='pathname';equal='=';value='options1';separator=':'}}
            ,@{TestInput = '-classpath','path\class.jar'; result = [PSCustomObject]@{PSTypeName='Java.Option.ClassPath';property='classpath';classpath='path\class.jar';}}
            ,@{TestInput = '-Dproperty=value'; result = [PSCustomObject]@{PSTypeName='Java.Option.DPropertyValue';property='property';value='value'};}
            ,@{TestInput = '-da:com.wombat.fruitbat...'; result = [PSCustomObject]@{PSTypeName='Java.Option.KeyValue';property='da';key='com.wombat.fruitbat...';separator=':'}}
    )

    foreach ($test in $listOfTests) {
        It "parses $($test.testInput) to $($test.result)" -Pending:(.{try{[bool]::Parse($test.pending)}catch{$false}}) {
            $propertiesToTest = $test.result | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
            $Result = Get-ArgumentFromToken -ArgumentsTokens $test.TestInput
            Compare-Object -ReferenceObject $test.result -DifferenceObject $result -Property $propertiesToTest | Should BeNullOrEmpty
            $Result.PSTypeNames | Should be $test.result.PSTypeNames
        }
    }
  }
}
