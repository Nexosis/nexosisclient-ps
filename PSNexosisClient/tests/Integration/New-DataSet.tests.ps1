# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

$script:jsonCreateAnswer = @"
{
    "dataSetName":  "[[dataSetName]]",
    "columns":  {
                    "sales":  {
                                  "dataType":  "numeric",
                                  "role":  "target",
                                  "imputation":  "zeroes",
                                  "aggregation":  "sum"
                              },
                    "timestamp":  {
                                      "dataType":  "date",
                                      "role":  "timestamp",
                                      "imputation":  "zeroes",
                                      "aggregation":  "sum"
                                  },
                    "transactions":  {
                                         "dataType":  "numeric",
                                         "role":  "none",
                                         "imputation":  "zeroes",
                                         "aggregation":  "sum"
                                     }
                }
}
"@

Describe "New-DataSet" -Tag 'Integration' {
	Context "Integration Tests" {
		Set-StrictMode -Version latest
		
		It "creates and deletes a new dataset" {			
			# generate a unique dataset name
			$dataSetName = "PSTest-Data-" + -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})

			# Create Test DataSet
			$columns = @{
				timestamp = @{
					dataType = "date"
					role = "timestamp"
					imputation = "zeroes"
					aggregation = "sum"
				}
				sales = @{
					dataType = "numeric"
					role = "target"
					imputation = $null
					aggregation = $null
				}
				transactions = @{
					dataType = "numeric"
					role = "none"
					imputation = "zeroes"
					aggregation = "sum"
				}
			}

			$data = @(
				@{
					timestamp = "2013-01-01T00:00:00+00:00"
					sales = "1500.56"
					transactions = "195.0"
				},
				@{
					timestamp = "2013-01-02T00:00:00+00:00"
					sales = "4078.52"
					transactions = "696.0"
				},
				@{
					timestamp = "2013-01-03T00:00:00+00:00"
					sales = "4545.69"
					transactions = "743.0"
				},
				@{
					timestamp = "2013-01-04T00:00:00+00:00"
					sales = "4872.63"
					transactions = "797.0"
				},
				@{
					timestamp = "2013-01-05T00:00:00+00:00"
					sales = "2420.81"
					transactions = "367.0"
				}
			)
			# Create new dataset
			New-DataSet -dataSetName $dataSetName -data $data -columnMetaData $columns | ConvertTo-Json -Depth 4 | Should Be ($jsonCreateAnswer -replace "\[\[dataSetName\]\]", $dataSetName)
			# Remove it
			Remove-Dataset -dataSetName $dataSetName -force
		}
	}
}