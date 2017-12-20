# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Get-NexosisContestChampion" -Tag 'Unit' {
	Context "unit tests" {
		Set-StrictMode -Version latest
		
		BeforeAll {
			$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\..\..\PSNexosisClient\PSNexosisClient.psd1).Version
			$TestVars = @{
				ApiKey       = $Env:NEXOSIS_API_KEY
				UserAgent	 = "Nexosis-PS-API-Client/$moduleVersion"
				ApiEndPoint	 = $Env:NEXOSIS_API_TESTURI
				MaxPageSize  = "1000"
                SessionId    = [Guid]::NewGuid()
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
        
	    It "loads contest champion by sessionId" {
			$results = Get-NexosisContestChampion -sessionId $TestVars.SessionId
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
		}

		It "uses the mock" {
			Assert-VerifiableMock
		}

		It "calls with the proper URI" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions/$($TestVars.SessionId)/contest/champion"
			} 
		}

		It "loads Contest Champion by SessionID with paging" {
			Get-NexosisContestChampion -sessionId $TestVars.SessionId -page 1 -pageSize 500 
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions/$($TestVars.SessionId)/contest/champion?page=1&pageSize=500"
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

		It "gets contest champion by sessionID including prediction interval" {
            Get-NexosisContestChampion -sessionId $TestVars.SessionID -page 1 -pageSize 50 -predictionInterval 0.5
            Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/sessions/$($TestVars.SessionId)/contest/champion?page=1&pageSize=50&predictionInterval=0.5"
			} 
		}
    }
}