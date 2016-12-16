function Get-JenkinsHomeFromSvcName {
    <#
      .SYNOPSIS
      Lookup the Jenkins Home folder from Installed Service Name.

      .DESCRIPTION
      This helper looks up the Path to the executable of a the given Jenkins service name,
      and returns its Parent as the Jenkins Home.

      .EXAMPLE
      Get-JenkinsHomeFromServiceId -ServiceId Jenkins
      #Output: C:\Program Files (x86)\Jenkins

      .PARAMETER ServiceId
      The Identifier of the service, known as id in the Jenkins.xml, or Service Name in the Windows Services mmc,
      and NOT the Display Name.
      
      #>
    [cmdletBinding()]
    [OutputType('io.FileInfo')]
    Param(
        [Parameter(
            ValueFromPipeline
            ,ValueFromPipelineByPropertyName
            )]
        [string]
        [Alias('ServiceName')]
        $ServiceId = 'Jenkins'
    )

    Process {

        if(!($Service = Get-CimInstance -ClassName win32_service | Where-Object { $_.name -match $ServiceId })) {
            Throw "The Service with Name $ServiceID was not found. Did you provide the DisplayName instead?"
        }

        Write-Output -InputObject ([io.fileInfo](split-path -Parent -Path ($Service.PathName -replace '"') ))
    }
}