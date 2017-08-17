# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Start-ImpactSession" -Tag 'Integration' {
	Context "Integration Tests" {
        Set-StrictMode -Version latest

        It "creates an impact session with columns metadata" {
		   # generate a unique dataset name
			$dataSetName = "PSTest-Start-ImpactSession-Integration"
			
			$columns = @{
				columns = @{
					timeStamp = @{
						dataType = "date"
						role = "timestamp"
					}
					sales = @{
						dataType = "numeric"
						role = "target"
					}
					transactions=  @{
						dataType = "numeric"
						role = "none"
					}
				}
			}
			# Create Test DataSet
			#$salesData = @{
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
		
			# Create new dataset
			New-DataSet -dataSetName $dataSetName -data $data -columnMetaData $columns
			
			$sessionResult = Start-ImpactSession -dataSetName $dataSetName -eventName 'integrationTest' -targetColumn 'sales' -startDate 2013-01-03 -endDate 2013-01-04 -resultInterval Day -columnsMetadata $columns
			
			# Status code only exists in error state
			Write-Verbose $sessionResult
            [bool]($sessionResult.PSobject.Properties.name -match "StatusCode") | should be $false
            ([Guid]$sessionResult.sessionID) | Should BeOfType [Guid]
			$sessionResult.type | should be 'impact'
			$sessionResult.status | should match "requested|started"
			
			# Remove it
			Remove-Dataset -dataSetName $dataSetName -force
		}

		 It "estimates an impact session with columns metadata" {
		   # generate a unique dataset name
			$dataSetName = "PSTest-Start-ImpactSession-Integration"
			
			$columns = @{
				columns = @{
					timeStamp = @{
						dataType = "date"
						role = "timestamp"
					}
					sales = @{
						dataType = "numeric"
						role = "target"
					}
					transactions=  @{
						dataType = "numeric"
						role = "none"
					}
				}
			}
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
		
			# Create new dataset
			New-DataSet -dataSetName $dataSetName -data $data -columnMetaData $columns
			
			$sessionResult = Start-ImpactSession -dataSetName $dataSetName -eventName 'integrationTest' -targetColumn 'sales' -startDate 2013-01-03 -endDate 2013-01-04 -resultInterval Day -columnsMetadata $columns -isEstimate
			
			# Status code only exists in error state
			Write-Verbose $sessionResult
            ([Guid]$sessionResult.sessionID) | Should BeOfType [Guid]
            $sessionResult.costEstimate | should match "^[+-]?\d+(\.\d+)? USD$"
			$sessionResult.type | should be 'impact'
			$sessionResult.status | should match "estimated"
			
			# Remove it
			Remove-Dataset -dataSetName $dataSetName -force
		}
    }
}