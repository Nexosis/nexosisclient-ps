$Verbose = @{}
# For build automation to enable verbose
if($ENV:NCBranchName -notlike "master" -or $env:NCCommitMessage -match "!verbose")
{
	$Verbose.add("Verbose",$True)
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

$jsonGetAlphaAnswer = @"
{
    "dataSetName":  "alpha.persistent",
    "columns":  {
                    "sales":  {
                                  "dataType":  "numeric",
                                  "role":  null,
                                  "imputation":  null,
                                  "aggregation":  null
                              },
                    "timeStamp":  {
                                      "dataType":  "date",
                                      "role":  "timestamp",
                                      "imputation":  null,
                                      "aggregation":  null
                                  },
                    "transactions":  {
                                         "dataType":  "numeric",
                                         "role":  null,
                                         "imputation":  null,
                                         "aggregation":  null
                                     }
                }
}
"@

Describe "Get-Dataset" -Tag 'Integration' {
	Context "Integration Tests" {
		Set-StrictMode -Version latest
		
		It "should return a list containing one dataset" {
			Get-DataSet -partialName 'alpha' -page 0 -pageSize 1 | ConvertTo-Json | Should Be $jsonGetAlphaAnswer
        }
	}
}