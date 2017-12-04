# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient" -Force

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Start-NexosisModelSession" -Tag 'Unit' {
	Context "Unit Tests" {
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
				Content=''
			}
			if($Headers['accept'] -eq 'application/json') {
				$response.Content = "{ }"
			} elseif ($Headers['accept'] -eq 'text/csv') {
				$response.Content = "A,B,C,D`r`n1,2,3,4`r`n"
			}
			$response
        } -Verifiable
		
		It "starts model session with all parameters" {
			Start-NexosisModelSession -dataSourceName 'name' -targetColumn 'SalePrice' -predictionDomain Regression -callbackUrl 'http://slackme.com' -isEstimate
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
		}

		It "uses the mock" {
			Assert-VerifiableMock
		}
		
		It "calls the correct URI" {		
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions/model"
			} 		
		}

		It "throws if columnMetaData paramter is not an array of hashes" {
			{ Start-NexosisModelSession -dataSourceName 'test' -predictionDomain Regression -columnMetadata '' }  | should Throw "Parameter '-ColumnMetaData' must be a hashtable of columns metadata for the data."
		}

		It "throws exception when dataSourceName is null or empty" {
			{ Start-NexosisModelSession -dataSourceName '       '  -predictionDomain Regression  } | Should throw "Argument '-DataSourceName' cannot be null or empty."
		}

		It "calls with the proper HTTP verb" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Post
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

		It "has proper HTTP body" {
			Enum PredictionDomain
			{
				Regression
			}

			$dataSourceName = 'HousingData'
			$targetColumn = 'SalePrice'
			$predictionDomain = [PredictionDomain]::Regression
			$isEstimate = $false

			$columns = @{
				columns = @{
					SalePrice = @{
						dataType = "numeric"
						role = "target"
					}
					LotFrontage = @{
						dataType = "numeric"
						role = "feature"
					}
					LotArea=  @{
						dataType = "numeric"
						role = "feature"
                    }
                    YearBuild=  @{
						dataType = "numeric"
						role = "feature"
					}
				}
            }
            
            $expected = @{
				dataSourceName = $dataSourceName
				targetColumn = $targetColumn
                predictionDomain = $predictionDomain.ToString().ToLower()
				columns = $columns.columns
			}

			Start-NexosisModelSession -dataSourceName $dataSourceName -targetColumn $targetColumn -predictionDomain $predictionDomain -columnMetadata $columns 
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$body -eq ($expected | ConvertTo-Json)
			}			
		}

		# Mock that includes Nexosis-Request-Cost Header
		Mock -ModuleName PSNexosisClient Invoke-WebRequest { 
			param($Uri, $Method, $Headers, $Body, $needHeaders)
			
			$response =  New-Object PSObject -Property @{
				StatusCode="200"
				Headers=@{}
				Content = "{ }"
			}
			$response.Headers.Add("Nexosis-Request-Cost","0.01 USD")
			$response
			
		} -Verifiable
		
		It "contains cost estimate" {
			$response = Start-NexosisModelSession -dataSourceName 'HousingData' -targetColumn 'SalePrice' -predictionDomain Regression -isEstimate
			$response.CostEstimate | Should be "0.01 USD"
		}
    }
}