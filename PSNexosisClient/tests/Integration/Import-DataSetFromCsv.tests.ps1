$Verbose = @{}
# For build automation to enable verbose
if($ENV:NCBranchName -notlike "master" -or $env:NCCommitMessage -match "!verbose")
{
	$Verbose.add("Verbose",$True)
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major
$ScriptRoot = $PSScriptRoot
Describe "Import-DataSetFromCsv" -Tag 'Integration' {
	Context "Integration Tests" {
		Set-StrictMode -Version latest
		
		It "uploads a csv, checks contents, and removes it" {
			$csvContents = Get-Content "$ScriptRoot\sample.csv"
			Import-DataSetFromCsv -dataSetName 'ps-csvimport' -csvFilePath "$ScriptRoot\sample.csv"
			((Get-DataSetData -dataSetName 'ps-csvimport').data | 
				ConvertTo-Csv -NoTypeInformation | % {$_.Replace('"','')} ) | Should Be $csvContents 
			Remove-DataSet -dataSetName 'ps-csvimport' -force
		}
	}
}
