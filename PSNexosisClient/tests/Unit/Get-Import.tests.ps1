# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Get-Import" -Tag 'Unit' {
	Context "unit tests" {
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
			param($Uri, $Method, $Headers, $ContentType)
            Write-Verbose $uri
		} -Verifiable

		It "loads imports by datasetname filter" {
			$results = Get-Import -dataSetName 'testName'
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
		}

		It "uses the mock" {
			Assert-VerifiableMocks
		}

		It "loads datasets by datasetname filter with paging" {
			$results = Get-Import -dataSetName 'blah' -page 0 -pageSize 1 
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/imports?dataSetName=blah&pageSize=1"
			} 
		}

		It "calls with the proper URI" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/imports?dataSetName=testName"
			} 
		}

        It "calls with the proper HTTP verb" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Get
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

		It "gets import by import id" {
			Get-Import -importId "015d7a16-8b2b-4c9c-865d-9a400e01a291"
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
		}

		It "calls with the proper URI for specifying ImportId" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/imports/015d7a16-8b2b-4c9c-865d-9a400e01a291"
			} 
        }
		
        It "throws when importID is null" {
			{ Get-Import -importId [GUID]$null } | should Throw 'Cannot process argument transformation on parameter 'importId'. Cannot convert value "[GUID]" to type "System.Guid". Error: "Guid should contain 32 digits with 4 dashes (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."'
		}
		
		It "gets imports by dataset name and requested before and after dates including paging defaults" {
            Get-Import -dataSetName 'salesdata' -requestedAfterDate 2017-01-01 -requestedBeforeDate 2017-01-20 
            Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/imports?dataSetName=salesdata&requestedAfterDate=01%2f01%2f2017+00%3a00%3a00&requestedBeforeDate=01%2f20%2f2017+00%3a00%3a00"
			} 
		}
		
		It "gets imports by dataset name with page and pageSize" {
            Get-Import -dataSetName 'salesdata' -page 1 -pageSize 1 
            Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/imports?dataSetName=salesdata&page=1&pageSize=1"
			} 
		}

		It "should throw error with invalid pagesize" {
			{Get-Import -dataSetName 'salesdata' -page 1 -pageSize 1001} | should throw "Parameter '-pageSize' must be an integer between 1 and $($TestVars.MaxPageSize)."
		}

		It "should throw error with invalid page param" {
			{Get-Import -dataSetName 'salesdata' -page -1 -pageSize 100} | should throw "Parameter '-page' must be an integer greater than 0."
		}
		
		Mock -ModuleName PSNexosisClient Invoke-WebRequest { 
			param($Uri, $Method, $Headers, $ContentType)
			# do code, return stuff.
			Return @{ StatusCode = 404 }
		} -Verifiable

		It "should have StatusCode" {
			$result = Get-Import -dataSetName 'salesdata' -page 1 -pageSize 1 
			$result.StatusCode | should be 404
		}
	}
}