$Verbose = @{}
# For build automation to enable verbose
if($ENV:NCBranchName -notlike "master" -or $env:NCCommitMessage -match "!verbose")
{
	$Verbose.add("Verbose",$True)
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Start-ForeacastSession" {
	Context "Unit Tests" {
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

		Mock -ModuleName PSNexosisClient Invoke-WebRequest { 
			param($Uri, $Method, $Headers, $Body) 
        } -Verifiable
		
		It "starts forecast session with all parameters" {
			Start-ForecastSession -dataSetName 'name' -targetColumn 'sales' -startDate 2017-01-01T00:00:00Z -endDate 2017-01-20T00:00:00Z -resultInterval Day -callbackUrl 'http://slackme.com' -isEstimate
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
		}

		It "uses the mock" {
			Assert-VerifiableMocks
		}
		
		It "calls the correct URI" {		
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions/forecast?dataSetName=name&targetColumn=sales&startDate=12%2f31%2f2016+19%3a00%3a00&endDate=01%2f19%2f2017+19%3a00%3a00&callbackUrl=http%3a%2f%2fslackme.com&isEstimate=true&resultInterval=Day"
			} 		
		}

		It "throws exception when dataSetName is null or empty" {
			{ Start-ForecastSession -dataSetName '       ' -startDate 01-01-2017 -endDate 01-20-2017 } | Should throw "Argument '-DataSetName' cannot be null or empty."
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

			Start-ForecastSession -dataSetName 'Location-A' -targetColumn 'sales' -startDate 2013-04-09T00:00:00Z -endDate 2013-11-09T00:00:00Z -resultInterval Day -columnsMetadata $columns 
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$body -eq ($columns	| ConvertTo-Json)
			}			
		}
    }
}