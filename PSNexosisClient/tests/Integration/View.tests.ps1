# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "New-NexosisView" -Tag 'Integration' {
	Context "Integration Tests" {
		Set-StrictMode -Version latest
        
        BeforeAll {
            # generate a unique dataset name
            $script:dataSetName = "PSTest-Data-" + -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
            $script:joinDataSetName = "PSTest-JoinData-" + -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
    
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
            New-NexosisDataSet -dataSetName $script:dataSetName -data $data -columnMetaData $columns

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
            # create two new datasets to make a view
            New-NexosisDataSet -dataSetName $script:dataSetName -data $data -columnMetaData $columns
            New-NexosisDataSet -dataSetName $script:joinDataSetName -data $eventData -columnMetaData $eventColumns
        }
   
		It "creates a new view" {			
			# generate a unique dataset name
			$script:viewName = "PSTest-View-" + -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
                    
            $joins = @(
                @{
                    dataSetName=$script:joinDataSetName
                    columnOptions = @{
                        isPromo=@{
                            alias="promo"
                        }
                    }
                }
            )
            
			# Create new dataset
            $viewResponse = New-NexosisView -viewName $script:viewName -dataSetName $script:dataSetName -joins $joins 
            
            { $viewResponse.StatusCode -eq 200 } | should be $true
            $viewResponse.viewName | should be $script:viewName
            $viewResponse.dataSetName | should be $script:dataSetName
            $viewResponse.joins[0].dataSet.name | should be $script:joinDataSetName
            $viewResponse.joins[0].columnOptions.isPromo | should not be $null
        }
             
        It "removes a view" {
            {Remove-NexosisView -viewName $script:viewName -force}  | should not throw
        }

        It "Should attempt to delete a missing view and get an error" {
            {Remove-NexosisView -viewName 'view123456' -force}  |  should throw "Item of type view with identifier view123456 was not found"
        }
	
        AfterAll {
            # Remove created datasets
            Remove-NexosisDataSet -dataSetName $script:dataSetName -force
            Remove-NexosisDataSet -dataSetName $script:joinDataSetName -force     
        }
	}
}