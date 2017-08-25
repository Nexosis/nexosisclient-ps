# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

# intentional extra `n at the end
$script:csvResults = @"
sales,timestamp,transactions
1500.56,2013-01-01T00:00:00+00:00,195.0
4078.52,2013-01-02T00:00:00+00:00,696.0
4545.69,2013-01-03T00:00:00+00:00,743.0
4872.63,2013-01-04T00:00:00+00:00,797.0
2420.81,2013-01-05T00:00:00+00:00,367.0

"@

$script:jsonResults = @"
[
    {
        "sales":  "1500.56",
        "timestamp":  "2013-01-01T00:00:00+00:00",
        "transactions":  "195.0"
    },
    {
        "sales":  "4078.52",
        "timestamp":  "2013-01-02T00:00:00+00:00",
        "transactions":  "696.0"
    },
    {
        "sales":  "4545.69",
        "timestamp":  "2013-01-03T00:00:00+00:00",
        "transactions":  "743.0"
    },
    {
        "sales":  "4872.63",
        "timestamp":  "2013-01-04T00:00:00+00:00",
        "transactions":  "797.0"
    },
    {
        "sales":  "2420.81",
        "timestamp":  "2013-01-05T00:00:00+00:00",
        "transactions":  "367.0"
    }
]
"@

Describe "All Dataset Tests" -Tag 'Integration' {
	Context "Integration Tests" {
        Set-StrictMode -Version latest
         
        BeforeAll {
            # generate a unique dataset name
            $script:dataSetName = "PSTest-Data-" + -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
        }

        It "creates a new dataset" {			
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
			$response = New-DataSet -dataSetName $script:dataSetName -data $data -columnMetaData $columns 
			$response.dataSetName | should be $script:dataSetName
			($response.columns).psobject.properties.Name -join ',' | should be 'sales,timeStamp,transactions'
        }

        It "should return a list containing one dataset" {
            $response = Get-DataSet -partialName $script:dataSetName -page 0 -pageSize 1 
            $response.DataSetName | should be $script:dataSetName
            ($response.columns).psobject.properties.Name -join ',' | should be 'sales,timeStamp,transactions'
        }

        It "checks the data in the dateset in CSV" {
            Get-DataSetData -dataSetName $script:dataSetName -ReturnCsv | Should Be ($csvResults.Replace("`r`n","`n"))
        }

        It "checks the data in the dateset in JSON" {
            (get-datasetdata -dataSetName $script:dataSetName).data | ConvertTo-Json | Should Be $script:jsonResults
        }
		
		It "Should attempt to delete a missing dataset and get an error" {
			{Remove-DataSet -dataSetName "test12345" -Force} | should throw "Item of type dataSet with identifier test12345 was not found"
		}
		
        AfterAll {
            Remove-Dataset -dataSetName $script:dataSetName -force
        }
    }
}