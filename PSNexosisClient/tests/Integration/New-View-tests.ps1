# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "New-View" -Tag 'Integration' {
	Context "Integration Tests" {
		Set-StrictMode -Version latest
         # generate a unique dataset name
        $script:dataSetName = "PSTest-Data-" + -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
        $script:joinDataSetName = "PSTest-JoinData-" + -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})

        BeforeAll {
            # Create Test DataSet to create view off of
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
            New-DataSet -dataSetName $script:dataSetName -data $data -columnMetaData $columns

            $eventColumns = @{
                timestamp = @{
                    dataType = "date"
                    role = "timestamp"
                }
                isPromo = @{
                    dataType = "numeric"
                    role = "feature"
                    imputation = "zeroes"
                }
            }

            $eventData = @(
                @{
                    timestamp = "2013-01-01T00:00:00+00:00"
                    isPromo = "0"
                },
                @{
                    timestamp = "2013-01-02T00:00:00+00:00"
                    isPromo = "0"
                },
                @{
                    timestamp = "2013-01-03T00:00:00+00:00"
                    isPromo = "1"
                },
                @{
                    timestamp = "2013-01-04T00:00:00+00:00"
                    isPromo = "1"
                },
                @{
                    timestamp = "2013-01-05T00:00:00+00:00"
                    isPromo = "0"
                }
            )

            New-DataSet -dataSetName $script:dataSetName -data $data -columnMetaData $columns
            New-DataSet -dataSetName $script:joinDataSetName -data $eventData -columnMetaData $eventColumns
        }
        
        AfterAll {
            # Remove created datasets
            Remove-Dataset -dataSetName $script:dataSetName -force
            Remove-Dataset -dataSetName $script:joinDataSetName -force     
        }

		It "creates and deletes a new view" {			
			# generate a unique dataset name
			$viewName = "PSTest-View-" + -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
                    
            $joins = @(
                @{
                    dataSetName=$script:joinDataSetName
                    
                    columnOptions = @{
                        isPromo=@{
                            alias="promo"
                            joinInterval="Day"
                        }
                    }
                }
            )
            
			# Create new dataset
			New-View -viewName $viewName -dataSetName $script:dataSetName -joins $joins -columnMetaData $columns | ConvertTo-Json -Depth 4 | Should Be ($jsonCreateAnswer -replace "\[\[dataSetName\]\]", $dataSetName)
			# Remove it
			Remove-View -viewName $viewName -force
		}
	}
}