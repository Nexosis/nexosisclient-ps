$Verbose = @{}
# For build automation to enable verbose
if($ENV:NCBranchName -notlike "master" -or $env:NCCommitMessage -match "!verbose")
{
	$Verbose.add("Verbose",$True)
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Get-SessionStatus" {
	Context "Integration tests" {
		Set-StrictMode -Version latest
		
        BeforeEach {
			$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\..\..\PSNexosisClient\PSNexosisClient.psd1).Version
            $TestVars = @{
                ApiKey       = $Env:NEXOSIS_API_KEY
				UserAgent	 = "Nexosis-PS-API-Client/$moduleVersion"
				ApiEndPoint	 = 'https://api.uat.nexosisdev.com/v1'
				MaxPageSize  = "1000"
            }
        }

        It "should get find session by sessionId" {
            $session = Get-Session -page 0 -pageSize 1
            $response = Get-SessionStatus -SessionId $session.SessionId
            $response | Should Match "Started|Requested|Completed|Cancelled|Failed|Estimated"
        }

        It "should return 404 with bad sessionId" {
            $response = Get-SessionStatus -SessionId ([guid]::NewGuid()) 
            $response.StatusCode | Should be 404
        }   
    }
}