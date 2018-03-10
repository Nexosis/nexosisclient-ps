# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Get-NexosisAccountBalance" -Tag 'Integration' {
	Context "integration tests" {
		Set-StrictMode -Version latest		

		BeforeEach {
			$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\..\..\PSNexosisClient\PSNexosisClient.psd1).Version
            $TestVars = @{
                ApiKey       = $Env:NEXOSIS_API_KEY
				UserAgent	 = "Nexosis-PS-API-Client/$moduleVersion"
				ApiEndPoint	 = $Env:NEXOSIS_API_TESTURI
				MaxPageSize  = "1000"
            }
        }

		It "gets account quotas" {
            $stats = Get-NexosisAccountQuota
			$stats.Count | should match 6
			$stats.'DataSetCount Current' | should match "^\d+$"
			$stats.'PredictionCount Allotted' | should match "^\d+$"
			$stats.'SessionCount Allotted' | should match "^\d+$"
			$stats.'SessionCount Current' | should match "^\d+$"
			$stats.'DataSetCount Allotted' | should match "^\d+$"
			$stats.'PredictionCount Current' | should match "^\d+$"
		}
	}
}