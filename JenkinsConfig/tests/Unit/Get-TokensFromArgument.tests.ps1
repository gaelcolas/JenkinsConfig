$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

Describe 'Get-TokensFromArgument' {

  Context 'General context'   {

    It 'runs without errors' {
        { Get-TokensFromArgument -Argument ([PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='client';}) } | Should Not Throw
    }

    It 'throws when argument is null'     {
      { Get-TokensFromArgument -Argument $null } | Should throw 
    }
  }

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
        It "Format $($test.result) to $($test.testInput)" -Pending:(.{try{[bool]::Parse($test.pending)}catch{$false}}) {
            $Result = Get-TokensFromArgument -Argument $test.result
            Compare-Object -ReferenceObject $test.TestInput -DifferenceObject $result | Should BeNullOrEmpty
        }
    }
  }
}
