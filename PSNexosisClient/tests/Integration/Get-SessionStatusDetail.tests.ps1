# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Get-SessionStatusDetail" -Tag 'Integration' {
	Context "integration tests" {
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

        It "should get session detail by sessionId" {
            $session = Get-Session -page 0 -pageSize 1
            $response = Get-SessionStatusDetail -SessionId $session.SessionId
            $response.SessionId | Should Be $session.SessionId
        }

        It "should return 404 with bad sessionId" {
            $response = Get-SessionStatusDetail -sessionId ([guid]::newGuid()) 
            $response.StatusCode | Should be 404
        }   
    }
}
