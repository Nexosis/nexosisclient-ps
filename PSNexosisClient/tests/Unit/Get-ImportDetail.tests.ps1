$Verbose = @{}
# For build automation to enable verbose
if($ENV:NCBranchName -notlike "master" -or $env:NCCommitMessage -match "!verbose")
{
	$Verbose.add("Verbose",$True)
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Get-ImportDetail" {
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
        param($Uri, $Method, $Headers, $ContentType)
    } -Verifiable
    
    Context "unit tests" {
        It "gets import details by result id" {
			Get-ImportDetail "015d7a16-8b2b-4c9c-865d-9a400e01a291"
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
		}
        
        It "uses the mock" {
			Assert-VerifiableMocks
        }
        
        It "calls with the proper URI" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/imports/015d7a16-8b2b-4c9c-865d-9a400e01a291"
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

        It "throws when importID is null" {
			{ Get-ImportDetail [GUID]$null } | should Throw 'Cannot process argument transformation on parameter 'importId'. Cannot convert value "[GUID]" to type "System.Guid". Error: "Guid should contain 32 digits with 4 dashes (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."'
        }
    }
}


