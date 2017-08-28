# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Get-NexosisDataSetData" -Tag 'Unit' {
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
        
        It "gets datasetdata by dataset name with paging" {
            Get-NexosisDataSetData -dataSetName 'salesdata' -page 1 -pageSize 1000
            Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
        }

		It "uses the mock" {
			Assert-VerifiableMocks
        }
		
		It "calls with the proper URI" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/data/salesdata?page=1&pageSize=1000"
			} 
		}

		It "throws exception when dataSetName is invalid" {
			{Get-NexosisDataSetData -dataSetName '       '} | Should throw "Argument '-DataSetName' cannot be null or empty."
		}

		It "throws error when page parameter is invalid" {
			{ Get-NexosisDataSetData -dataSetName 'testName' -Page -1 } | Should throw "Parameter '-page' must be an integer greater than 0."
		}

		It "throws error when pageSize parameter is invalid" {
			{ Get-NexosisDataSetData -dataSetName	 'testName' -PageSize -1 } | Should throw "Parameter '-pageSize' must be an integer between 1 and $($TestVars.MaxPageSize)."
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

		It "has proper HTTP Headers for CSV" {
			Get-NexosisDataSetData -dataSetName 'test' -ReturnCsv
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				(
					($Headers.Contains("accept")) -and 
					($Headers.Get_Item("accept") -eq 'text/csv')
				)
			}
		}

		It "gets datasetdata by dataset name and dates with paging defaults" {
            Get-NexosisDataSetData -dataSetName 'salesdata' -startDate 2017-01-01 -endDate 2017-01-20
            Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/data/salesdata?startDate=01%2f01%2f2017+00%3a00%3a00&endDate=01%2f20%2f2017+00%3a00%3a00"
			} 
		}
		
		It "uses correct URI for multiple include columns" {
			Get-NexosisDataSetData -dataSetName 'Location-A' -include @('sales','transactions') 
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/data/Location-A?include=sales&include=transactions"
			}
		}
	}
}
