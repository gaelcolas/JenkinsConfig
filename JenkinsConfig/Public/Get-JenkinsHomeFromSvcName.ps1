function Get-JenkinsHomeFromSvcName {
    <#
      .SYNOPSIS
      Lookup the Jenkins Home folder from Installed Service Name.

      .DESCRIPTION
      This helper looks up the Path to the executable of a the given Jenkins service name,
      and returns its Parent as the Jenkins Home.

      .EXAMPLE
      Get-JenkinsHomeFromSvcName -ServiceId Jenkins
      #Output: C:\Program Files (x86)\Jenkins

      .PARAMETER ServiceId
      The Identifier of the service, known as id in the Jenkins.xml, or Service Name in the Windows Services mmc,
      and NOT the Display Name.
      
      #>
    [cmdletBinding()]
    [OutputType('io.DirectoryInfo')]
    Param(
        [Parameter(
            ValueFromPipeline
            ,ValueFromPipelineByPropertyName
            )]
        [string]
        [Alias('ServiceName')]
        $ServiceId = 'Jenkins'
    )

    Begin {
        if (!$ServiceId) {
            $ServiceId = 'Jenkins'
        }
    }

    Process {

        if(!($Service = Get-CimInstance -ClassName win32_service | Where-Object { $_.name -match $ServiceId })) {
            Throw "The Service with Name $ServiceID was not found. Did you provide the DisplayName instead?"
        }
        else {
            Write-Output -InputObject ([io.DirectoryInfo](split-path -Parent -Path ($Service.PathName -replace '"') ))
        }
    }
}