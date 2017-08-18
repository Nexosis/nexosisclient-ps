# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

$testBody = @"
{
    "columns":  {

                },
    "data":  [

             ],
    "dataSetName":  "testnew"
}
"@

Describe "New-DataSet" {
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

		It "throws if DataSetName is null or empty" {
			{ New-DataSet -dataSetName '' -data @() }  | should Throw "Cannot bind argument to parameter 'dataSetName' because it is an empty string."
		}

		It "throws if DataSetName is invalid" {
			{ New-DataSet -dataSetName '     ' -data @() }  | should Throw "Argument '-DataSetName' cannot be null or empty."
		}

		It "throws if data is null or empty" {
			{ New-DataSet -dataSetName 'notnull' -data $null}  | should Throw "Cannot bind argument to parameter 'data' because it is null."
		}

		It "throws if data paramter is not an array" {
			{ New-DataSet -dataSetName 'notnull' -data "blah"}  | should Throw "Parameter '-data' must be an array of hashes."   
		}

		It "throws if columnMetaData paramter is not an array of hashes" {
			{ New-DataSet -dataSetName 'notnull' -data @() -columnMetaData "string" }  | should Throw "Parameter '-columnMetaData' must be a hashtable of column metadata for the data."
		}

		It "puts new data and metadata with a name" {
			New-DataSet -dataSetName "testnew" -data @() -columnMetaData @{}
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
		}

		It "calls with the correct URI" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/data/testnew"
			}
        }
		
		It "calls with the correct body" {
			# Converting from string to json and back seems to remove 
			# any extra whitespace, formatting, etc. so they compare acutal contents.
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				($Body | ConvertFrom-Json | ConvertTo-Json) -eq ($testBody | ConvertFrom-Json | ConvertTo-Json)
			}
        }

		It "calls with the proper HTTP verb" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Put
			}
		}
	}
}
