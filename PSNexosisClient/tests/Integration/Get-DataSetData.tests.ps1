# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}
Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

# intentional extra `n at the end
$csvResults = @"
sales,timestamp,transactions
1500.56,2013-01-01T00:00:00+00:00,195.0
4078.52,2013-01-02T00:00:00+00:00,696.0
4545.69,2013-01-03T00:00:00+00:00,743.0
4872.63,2013-01-04T00:00:00+00:00,797.0
2420.81,2013-01-05T00:00:00+00:00,367.0

"@

Describe "Get-DatasetData" -Tag 'Integration' {
	Context "Integration Tests" {
		Set-StrictMode -Version latest
        
        # Create Test DataSet
			
		$columns = @{
			timestamp = @{
				dataType = "date"
				role = "timestamp"
			}
			sales = @{
				dataType = "numeric"
				role = "target"
			}
			transactions = @{
				dataType = "numeric"
				role = "none"
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
        
        It "should create a dataset and return the CSV contents" {
            New-DataSet -dataSetName 'PSTest' -data $data -columnMetaData $columns
            Get-DataSetData -dataSetName 'PSTest' -ReturnCsv | Should Be ($csvResults.Replace("`r`n","`n"))
            Remove-DataSet 'PSTest' -Force
		}
	}
}