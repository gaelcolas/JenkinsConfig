$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here/../../*/$sut" #for files in Public\Private folders, called from the tests folder

Describe 'Merge-Arguments' {

  Context 'General test'   {
    $param = @{
        UpdateSource = @([PSCustomObject]@{PSTypeName='Java.Option.DPropertyValue';property='property';value='property'})
        ExistingArguments = @([PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='client';},[PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='server';},[PSCustomObject]@{PSTypeName='Java.Option.DPropertyValue';property='property';value='value'})
        ResolutionBehavior = 'UpdateOnly'
    }
    $ExpectedResult = @([PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='client';},[PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='server';},[PSCustomObject]@{PSTypeName='Java.Option.DPropertyValue';property='property';value='property'})
    It 'runs without errors' {
        { Merge-Arguments @param } | Should Not Throw
    }

    It 'runs the basic test' {
        $result = Merge-Arguments @param
        foreach ($element in $ExpectedResult) {
            $properties = $element | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
            $index = $ExpectedResult.IndexOf($element)
            Compare-Object -referenceObject $element -differenceObject $result[$index] -Property $properties | Should BeNullOrEmpty
        }
    }

    It 'Throws if UpdateSource and ExistingArgs is null'     {
      { Merge-Arguments -UpdateSource $null -ExistingArguments $null } | Should throw 
    }
  }
  
  $listOfTest = @(
    @{
        UpdateSource = @([PSCustomObject]@{PSTypeName='Java.Option.DPropertyValue';property='property';value='property'})
        ExistingArguments = @([PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='client';},[PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='server';},[PSCustomObject]@{PSTypeName='Java.Option.DPropertyValue';property='property';value='value'})
        ResolutionBehavior = 'UpdateOnly'
        ExpectedResult = @([PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='client';},[PSCustomObject]@{PSTypeName='Java.Option.SingleKey';property='server';},[PSCustomObject]@{PSTypeName='Java.Option.DPropertyValue';property='property';value='property'})
    }

  )


  Context 'Test multiple Cases for multiple ResolutionBehaviour' {
    foreach ($test in $listOfTest) {
        $param = @{
            UpdateSource = $test.UpdateSource
            ExistingArguments = $test.ExistingArguments
            ResolutionBehavior = $test.ResolutionBehavior
        }

        It "Test $($test.UpdateSource) in mode $($test.ResoluionBehavior)" {
            if ($test.ResolutionBehavior -match 'Error') {
                if ($test.ExpectedResult -match 'error') {
                    { Merge-Arguments @param } | Should Throw
                }
                else {
                    { Merge-Arguments @param } | Should Not Throw
                }
            }
            else {
                $result = Merge-Arguments @param
                foreach ($element in $test.ExpectedResult) {
                    $properties = ($element | Get-Member -MemberType NoteProperty).Name
                    $index = $test.ExpectedResult.IndexOf($element)
                    Compare-Object -referenceObject $element -differenceObject $result[$index] -Property $properties | Should BeNullOrEmpty
                }
            }
        }
    }
  }
}
