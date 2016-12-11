function Get-TokenizedCommand {
    <#
      .SYNOPSIS
      Splits a command to an array of tokens
      
      .DESCRIPTION
      Splits a CLI command using spaces as delimiter, unless the space is within quotes.
      It Trims the element, and allows you to ignore empty tokens
      
      .EXAMPLE
      $cmd = 'Java.exe -Xrs -Xmx256m -Dhudson.lifecycle=hudson.lifecycle.WindowsServiceLifecycle -Djenkins.install.runSetupWizard=false -Jar "%BASE%\jenkins.war" --httpPort=8080 --webroot="%BASE%\war"'
      $result = [String[]]@()
      $result = Get-TokenizedCommand
      
      .EXAMPLE
      Get-TokenizedCommand '-Xrs   -Jar    "C:\Program Files\Jenkins\Jenkins.Jar"' -RemoveEmptyToken
      
      .PARAMETER InputObject
      String to be Tokenized, this can also be passed by pipeline or property name.
      
      .PARAMETER RemoveEmptyToken
      This will remove the empty tokens, such that only returns tokens with a value (no extra space)
      #>
    [cmdletBinding()]
    [OutputType('String[]')]
    Param(
        [Parameter(
            Mandatory
            ,HelpMessage='Provide the Argument strings to tokenize'
            ,ValueFromPipeline
            ,ValueFromPipelineByPropertyName
            )]
        [string]
        $InputObject,
        [switch]
        $RemoveEmptyToken
    )

    Process {
        $openedQuote = $false
        $TokenizedValues = $stack = @()

        foreach ($result in $InputObject) {
            foreach ($item in ($result -split '\s')) {
                if ($item -match '[^\\]?"' -and $item -notmatch '".*"$') {
                    $openedQuote = !$openedQuote
                    $stack += $item
                    if(!$openedQuote) {
                        $TokenizedValues += ($stack -join ' ').Trim()
                        $stack = @()
                    }
                }
                elseif($openedQuote) {
                    $stack += $item
                }
                else {
                    if ($item.Trim() -eq [String]::Empty -and $RemoveEmptyToken.IsPresent) {
                        Write-Verbose -Message "Not adding Empty Token $item"
                    }
                    else {
                        $TokenizedValues += $item.Trim()
                    }
                }
            }
            Write-Output -InputObject $TokenizedValues
        }
    }
}