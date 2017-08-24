# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major
$ScriptRoot = $PSScriptRoot

Describe "Import-DataSetFromCsv" -Tag 'Integration' {
	Context "Integration Tests" {
		Set-StrictMode -Version latest
		
		BeforeAll {
			$script:csvContents = Get-Content "$ScriptRoot\sample.csv"
			Import-DataSetFromCsv -dataSetName 'ps-csvimport' -csvFilePath "$ScriptRoot\sample.csv"
		}

		It "uploads a csv" {
			Import-DataSetFromCsv -dataSetName 'ps-csvimport' -csvFilePath "$ScriptRoot\sample.csv"
		}

		It "It confirms dataset contents match CSV data" {
			((Get-DataSetData -dataSetName 'ps-csvimport').data | 
				ConvertTo-Csv -NoTypeInformation | % {$_.Replace('"','')} ) | Should Be $script:csvContents 
		}

		AfterAll {
			Remove-DataSet -dataSetName 'ps-csvimport' -force
		}
	}
}

