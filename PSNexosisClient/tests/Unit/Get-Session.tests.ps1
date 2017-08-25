# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Get-Session" -Tag 'Unit' {
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
        
	    It "loads session by dataSourceName filter" {
			$results = Get-Session -dataSourceName 'testSession'
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
		}

		It "uses the mock" {
			Assert-VerifiableMocks
		}

		It "loads session by dataSourceName filter with paging" {
			$results = Get-Session -dataSourceName 'blah' -page 0 -pageSize 1 
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions?dataSourceName=blah&pageSize=1"
			} 
		}

		It "calls with the proper URI" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions?dataSourceName=testSession"
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

		It "gets session by dataSourceName name and requested before and after dates including paging defaults" {
            Get-Session -dataSourceName 'salesdata' -requestedAfterDate 2017-01-01 -requestedBeforeDate 2017-01-20 
            Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions?dataSourceName=salesdata&requestedAfterDate=01%2f01%2f2017+00%3a00%3a00&requestedBeforeDate=01%2f20%2f2017+00%3a00%3a00"
			} 
		}
		
		It "gets session by dataSource name with page and pageSize" {
            Get-Session -dataSourceName 'salesdata' -page 1 -pageSize 1 
            Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions?dataSourceName=salesdata&page=1&pageSize=1"
			} 
		}

		It "should throw error with invalid pagesize" {
			{Get-Session -dataSourceName 'salesdata' -page 1 -pageSize 1001} | should throw "Parameter '-pageSize' must be an integer between 1 and $($TestVars.MaxPageSize)."
		}

		It "should throw error with invalid page" {
			{Get-Session -dataSourceName 'salesdata' -page -1 -pageSize 100} | should throw "Parameter '-page' must be an integer greater than 0."
		}
    }
}