$Verbose = @{}
# For build automation to enable verbose
if($ENV:NCBranchName -notlike "master" -or $env:NCCommitMessage -match "!verbose")
{
	$Verbose.add("Verbose",$True)
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

$jsonDeleteNotFoundAnswer = @"
{
    "statusCode":  404,
    "message":  "Item of type dataSet with identifier test12345 was not found",
    "errorType":  "NotFound",
    "errorDetails":  {
                         "itemType":  "dataSet",
                         "itemId":  "test12345",
                         "companyId":  "3c7e14b0-a9ab-4f3a-b5fa-4d0670283ddf"
                     }
}
"@

Describe "Remove-Datasets"  -Tag 'Integration' {
	Context "Integration Tests" {
        Set-StrictMode -Version latest
        
		It "Should attempt to delete a missing dataset and get a 404" {
			$testResult = Remove-DataSet -dataSetName "test12345" -Force
			$testResult | ConvertTo-Json | Should Be $jsonDeleteNotFoundAnswer 
			$testResult.StatusCode | Should Be 404
        }
	}
}
