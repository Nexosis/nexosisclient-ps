# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

$stringOutput = 
@'
{
    "startDate":  "2013-04-08T20:00:00.0000000-04:00",
    "columns":  {
                    "sales":  {
                                  "dataType":  "numeric",
                                  "role":  "target"
                              },
                    "timeStamp":  {
                                      "dataType":  "date",
                                      "role":  "timestamp"
                                  },
                    "transactions":  {
                                         "dataType":  "numeric",
                                         "role":  "none"
                                     }
                },
    "endDate":  "2013-11-08T19:00:00.0000000-05:00",
    "resultInterval":  "Day",
    "name":  "forecast session name",
    "targetColumn":  "sales",
    "dataSourceName":  "Location-A"
}
'@

Describe "Start-ForeacastSession" -Tag 'Unit' {
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
		
		It "starts forecast session with all parameters" {
			Start-NexosisForecastSession -dataSourceName 'name' -targetColumn 'sales' -startDate 2017-01-01 -endDate 2017-01-20 -resultInterval Day -callbackUrl 'http://slackme.com'
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
		}

		It "uses the mock" {
			Assert-VerifiableMock
		}
		
		It "calls the correct URI" {		
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions/forecast"
			} 		
		}

		It "throws exception when dataSourceName is null or empty" {
			{ Start-NexosisForecastSession -dataSourceName '       ' -startDate 01-01-2017 -endDate 01-20-2017 } | Should throw "Argument '-DataSourceName' cannot be null or empty."
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
			$requestobj = ($stringOutput | convertFrom-json)
		
			Start-NexosisForecastSession -name 'forecast session name' -dataSourceName 'Location-A' -targetColumn 'sales' -startDate 2013-04-09T00:00:00Z -endDate 2013-11-09T00:00:00Z -resultInterval Day -columnMetadata $requestobj.columns 
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$body -eq $stringOutput
			}			
		}
    }
}