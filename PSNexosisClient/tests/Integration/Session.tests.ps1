# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "All Session Tests" -Tag 'Integration' {
	Context "Integration tests" {
		Set-StrictMode -Version latest
		
        BeforeAll {
            $script:dsName = 'Location-A'

            $response = Import-NexosisDataSetFromS3 `
                        -dataSetName $script:dsName `
                        -S3BucketName "nexosis-sample-data" `
                        -S3BucketPath "LocationA.csv" `
                        -S3Region "us-east-1"

            $script:ImportId = $response.ImportID

             # Make sure import is completed before creating a session
             do {
                $status = Get-NexosisImport -importId $script:ImportId
            } while ($status.status -ne "completed")
        }

        it "should start a forecast session" {
            $script:session = Start-NexosisForecastSession -dataSourceName $script:dsName -targetColumn 'sales' -startDate 2015-09-30 -endDate 2015-10-30 -resultInterval Day
            ([guid]$script:session.sessionId) |  Should BeOfType [Guid]
            
            # Status code only exists in error state
            [bool]($script:session.PSobject.Properties.name -match "StatusCode") | should be $false
            $script:session.type | should be 'forecast'
			$script:session.status | should match "requested|started"
        }

        It "should get session by sessionId" {
            $response = Get-NexosisSessionStatus -SessionId $script:session.SessionId
            $response | Should Match "Started|Requested|Completed|Cancelled|Failed|Estimated"
        }

        It "should find a session by sessionId" {
            $response = Get-NexosisSession -dataSourceName  $script:dsName -page 0 -pageSize 1
            $response.status | Should Match "Started|Requested|Completed|Cancelled|Failed|Estimated"
        }

        It "should get session status detail by sessionId" {
            $response = Get-NexosisSessionStatusDetail -SessionId $script:session.SessionId
            $response.SessionId | Should Be $script:session.SessionId
        }

        It "should return 404 with bad sessionId for SessionStatus" {
            {Get-NexosisSessionStatus -SessionId ([guid]::NewGuid())} | should throw "Not Found"
        }

        It "should return 404 with bad sessionId for SessionStatusDetail" {
            $guid = [guid]::NewGuid()
            {Get-NexosisSessionStatusDetail -sessionId $guid} | should throw "Item of type session with identifier $guid was not found"
        } 

        AfterAll {
            Remove-NexosisDataSet -dataSetName $script:dsName -cascadeOption Sessions -force
        }
    }
}