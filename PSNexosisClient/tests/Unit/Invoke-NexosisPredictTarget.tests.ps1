# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major
$scriptRoot = $PSScriptRoot

$data = @(
	@{
		LotFrontage= "65"
		LotArea = "8450"
		YearBuilt="2003"
	}
	@{
		LotFrontage = "80"
		LotArea = "96000"
		YearBuilt = "1976"
	}
	@{
		LotFrontage = "68"
		LotArea = "11250"
		YearBuilt = "2001"
	}
)  

$jsonPostBody = @{ data = $data } | ConvertTo-Json

Describe "Invoke-NexosisPredictTarget" -Tag 'Unit' {
	Context "Unit Tests" {
		Set-StrictMode -Version latest

		BeforeAll {
			$modelId = [Guid]::NewGuid()
			$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\..\..\PSNexosisClient\PSNexosisClient.psd1).Version
            $TestVars = @{
                ApiKey       = $Env:NEXOSIS_API_KEY
				UserAgent	 = "Nexosis-PS-API-Client/$moduleVersion"
				ApiEndPoint	 = "https://fake.url/v1"
				MaxPageSize  = "1000"
				dsName = 'Location-A'
				bucketName = 'nexosis-sample-data'
				s3path = 'LocationA.csv'
				s3region = 'us-east-1'
            }

            Set-NexosisConfig -ApiBaseUrl "https://fake.url/v1"
		}

		Mock -ModuleName PSNexosisClient Invoke-WebRequest { 
			param($Uri, $Method, $Headers, $ContentType, $Body, $InFile)
            $response =  New-Object PSObject -Property @{
				StatusCode="200"
				Headers=@{}
				Content=''
			}
			if($Headers['accept'] -eq 'application/json') {
				$response.Content = "{ }"
			} elseif ($Headers['accept'] -eq 'text/csv') {
				$response.Content = "A,B,C,D`r`n1,2,3,4`r`n"
			}
			$response
        } -Verifiable

		It "mock is called once" {
			Invoke-NexosisPredictTarget -modelId $modelId -data $data
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context
		}

		It "calls with the proper URI" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/models/$modelId/predict"
			}
		}

		It "calls with correct JSON body" {
			# Converting from string to json and back seems to remove 
			# any extra whitespace, formatting, etc. so they compare acutal contents.
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				($Body | ConvertFrom-Json | ConvertTo-Json) -eq ($jsonPostBody | ConvertFrom-Json | ConvertTo-Json)
			}
		}

		It "uses the mock" {
			Assert-VerifiableMocks
		}

		It "calls with the proper HTTP verb" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Post
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
		
		It "should throw if modelId is not a GUID" {
			{ Invoke-NexosisPredictTarget -modelId '' }  | should Throw "Cannot process argument transformation on parameter 'ModelId'. Cannot convert value `"`" to type `"System.Guid`". Error: `"Unrecognized Guid format.`""
		}

		It "should throw if param data is not an array" {
			{ Invoke-NexosisPredictTarget -modelId $modelId -data '' }  | should Throw "Parameter '-data' must be an array containing a hashtable of features needed to make the prediction."
		}

		It "should throw if param data is not an array containing a hashtable" {
			{ Invoke-NexosisPredictTarget -modelId $modelId -data @() }  | should Throw "Parameter '-data' must be an array containing a hashtable of features needed to make the prediction."
		}
	}
}
