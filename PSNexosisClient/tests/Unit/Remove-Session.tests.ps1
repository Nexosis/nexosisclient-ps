# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Remove-Session" {
	Context "Unit tests" {
		Set-StrictMode -Version latest
		
		Mock -ModuleName PSNexosisClient Invoke-WebRequest { 
			param($Uri, $Method, $Headers)
		} -Verifiable

		BeforeAll {
			$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\..\..\PSNexosisClient\PSNexosisClient.psd1).Version
			$TestVars = @{
				ApiKey       = $Env:NEXOSIS_API_KEY
				UserAgent	 = "Nexosis-PS-API-Client/$moduleVersion"
				ApiEndPoint	 = 'https://api.uat.nexosisdev.com/v1'
				MaxPageSize  = "1000"
			}
		}
        
        $sessionId = [guid]::NewGuid()
		It "deletes one session by sessionid" {
			Remove-Session -sessionid $sessionId -force
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
        }
        
        It "delete many sessions for one dataset by session type" {
            Remove-Session -dataSetName 'test' -sessionType 'forecast' -force
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
        }

		It "uses the mock" {
			Assert-VerifiableMocks
		}

		It "calls delete with the proper URI" {
            Remove-Session -dataSetName 'test' -sessionType 'impact' -force
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions?sessionType=impact&dataSetName=test"
			} 
		}

		It "calls with the proper HTTP verb" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Delete
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

		It "throws exception with sessionId is invalid" {
			{ Remove-Session -sessionId '      ' } | Should throw "Cannot process argument transformation on parameter 'sessionId'. Cannot convert value `"      `" to type `"System.Guid`". Error: `"Unrecognized Guid format.`""
		}

		It "removes session by sessionid name and dates" {
            Remove-Session -dataSetName 'testName' -sessionType 'impact' -requestedBeforeDate 2017-01-01 -requestedAfterDate 2017-01-20 -force 
            Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions?sessionType=impact&dataSetName=testName&requestedAfterDate=01%2f20%2f2017+00%3a00%3a00&requestedBeforeDate=01%2f01%2f2017+00%3a00%3a00"
			} 
        }

        It "makes sure SessionID param is exclusive" {
            {Remove-Session -sessionId ([guid]::NewGuid()) -sessionType 'impact'} | Should throw "Parameter '-SessionID' is exclusive and cannot be used with any other parameters."
        }

        It "should fail if sessionType is not Impact or Forecast" {
          {Remove-Session -dataSetName 'testName' -sessionType 'sadasddas'} | Should throw  "Invalid parameter specified for '-SessionType.' Valid options are 'forecast' and 'impact.'"
        }
	}
}