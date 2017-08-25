# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Start-ForeacastSession" -Tag 'Unit' {
	Context "Unit Tests" {
		Set-StrictMode -Version latest
		
		BeforeAll {
			$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\..\..\PSNexosisClient\PSNexosisClient.psd1).Version
			$TestVars = @{
				ApiKey       = $Env:NEXOSIS_API_KEY
				UserAgent	 = "Nexosis-PS-API-Client/$moduleVersion"
				ApiEndPoint	 = 'https://api.uat.nexosisdev.com/v1'
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
		
		It "starts forecast session with all parameters" {
			Start-ForecastSession -dataSourceName 'name' -targetColumn 'sales' -startDate 2017-01-01 -endDate 2017-01-20 -resultInterval Day -callbackUrl 'http://slackme.com' -isEstimate
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
		}

		It "uses the mock" {
			Assert-VerifiableMocks
		}
		
		It "calls the correct URI" {		
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions/forecast?dataSourceName=name&targetColumn=sales&startDate=01%2f01%2f2017+00%3a00%3a00&endDate=01%2f20%2f2017+00%3a00%3a00&callbackUrl=http%3a%2f%2fslackme.com&isEstimate=true&resultInterval=Day"
			} 		
		}

		It "throws if columnMetaData paramter is not an array of hashes" {
			{ Start-ForecastSession -dataSourceName 'notnull' -startDate 01-01-2017 -endDate 01-20-2017 -columnMetaData "string" }  | should Throw "Parameter '-columnMetaData' must be a hashtable of column metadata for the data."
		}

		It "throws exception when dataSourceName is null or empty" {
			{ Start-ForecastSession -dataSourceName '       ' -startDate 01-01-2017 -endDate 01-20-2017 } | Should throw "Argument '-DataSourceName' cannot be null or empty."
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
			$columns = @{
				columns = @{
					timeStamp = @{
						dataType = "date"
						role = "timestamp"
					}
					sales = @{
						dataType = "numeric"
						role = "target"
					}
					transactions=  @{
						dataType = "numeric"
						role = "none"
					}
				}
			}

			Start-ForecastSession -dataSourceName 'Location-A' -targetColumn 'sales' -startDate 2013-04-09T00:00:00Z -endDate 2013-11-09T00:00:00Z -resultInterval Day -columnMetadata $columns 
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$body -eq ($columns	| ConvertTo-Json)
			}			
		}

		It "starts a forecast session with all parameters" {
			Start-ForecastSession -dataSourceName 'name'-targetColumn 'sales' -startDate 2017-01-01 -endDate 2017-01-20 -resultInterval Day -callbackUrl 'http://slackme.com' -isEstimate
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions/forecast?dataSourceName=name&targetColumn=sales&startDate=01%2f01%2f2017+00%3a00%3a00&endDate=01%2f20%2f2017+00%3a00%3a00&callbackUrl=http%3a%2f%2fslackme.com&isEstimate=true&resultInterval=Day"
			}	
		}

		It "starts a forecast session with all parameters except estimate" {
			Start-ForecastSession -dataSourceName 'name' -targetColumn 'sales' -startDate 2017-01-01 -endDate 2017-01-20 -resultInterval Day -callbackUrl 'http://slackme.com'
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions/forecast?dataSourceName=name&targetColumn=sales&startDate=01%2f01%2f2017+00%3a00%3a00&endDate=01%2f20%2f2017+00%3a00%3a00&callbackUrl=http%3a%2f%2fslackme.com&resultInterval=Day"
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
			$response = Start-ForecastSession -dataSourceName 'name' -targetColumn 'sales' -startDate 2017-01-01 -endDate 2017-01-20 -resultInterval Day -isEstimate
			$response.CostEstimate | Should be "0.01 USD"
		}
    }
}