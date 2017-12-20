# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major
Describe "Get-NexosisAccountQuotas" -Tag 'Unit' {
	Context "unit tests" {
		Set-StrictMode -Version latest		

		BeforeAll {
			$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\..\..\PSNexosisClient\PSNexosisClient.psd1).Version
            $TestVars = @{
                ApiKey       = $Env:NEXOSIS_API_KEY
				UserAgent	 = "Nexosis-PS-API-Client/$moduleVersion"
				ApiEndPoint	 = $Env:NEXOSIS_API_TESTURI
				MaxPageSize  = "1000"
            }
        }

		Mock -ModuleName PSNexosisClient Invoke-WebRequest { 
			param($Uri, $Method, $Headers, $ContentType, $Body, $InFile)
            $response =  New-Object PSObject -Property @{
				StatusCode="200"
				Headers=@{}
			}
			$response.Headers.Add("Nexosis-Account-DataSetCount-Current","181")
			# Next one will be eventually removed, include in test to make sure it gets removed
			$response.Headers.Add("Nexosis-Account-Balance","200 USD")
			$response.Headers.Add("Nexosis-Account-PredictionCount-Allotted","250000")
			$response.Headers.Add("Nexosis-Account-SessionCount-Allotted","3500")
			$response.Headers.Add("Nexosis-Account-SessionCount-Current","0")
			$response.Headers.Add("Nexosis-Account-DataSetCount-Allotted","200")
			$response.Headers.Add("Nexosis-Account-PredictionCount-Current","0")
			$response
        } -Verifiable
	
		It "gets account quotas" {
			$value = Get-NexosisAccountQuotas
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
			$value.Count | should match 6
			$value.'DataSetCount Current' | should match "^\d+$"
			$value.'PredictionCount Allotted' | should match "^\d+$"
			$value.'SessionCount Allotted' | should match "^\d+$"
			$value.'SessionCount Current' | should match "^\d+$"
			$value.'DataSetCount Allotted' | should match "^\d+$"
			$value.'PredictionCount Current' | should match "^\d+$"
		}
        
		It "uses the mock" {
			Assert-VerifiableMock
		}
        
		It "calls with the proper URI" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/data?page=0&pageSize=1"
			} 
		}

        It "calls with the proper content-type" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$ContentType -eq 'application/json'
			}
        }

        It "has proper HTTP headers" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				(
					($Headers.Contains("accept")) -and 
					($Headers.Contains("api-key")) -and
					($Headers.Contains("User-Agent")) -and
					($Headers.Get_Item("accept") -eq 'application/json') -and
					($Headers.Get_Item("api-key") -eq $TestVars.ApiKey) -and
					($Headers.Get_Item("User-Agent") -eq $TestVars.UserAgent)
				)
			}
		}
	}
}