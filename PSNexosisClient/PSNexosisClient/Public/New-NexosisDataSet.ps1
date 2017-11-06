Function New-NexosisDataSet {
<# 
 .Synopsis
  This operation creates a new dataset or updates an existing dataset using data from a PSCustomObject.

 .Description
  This operation creates a new dataset using data provided in an object formatted as an Array of HashTables, like so:

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

  Optionally, metadata for the columns can be submitted to help describe the data being uploaded as a hashtable, for example:
  
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

  If the dataset already exists, adds rows to the dataset. If the specified data contains records with timestamps that
  already exist in the dataset, those records will be overwritten.

 .Parameter DataSetName
  Name of the dataset to create or which to add data
  
 .Parameter Data  
  An object array containing data used to submit as a dataset.

  .Parameter ColumnMetaData  
  A hashtable containing metadata that describes submitted data, such as data types and imputation and aggragation strategies.

 .Example
  # create a new dataset using an array of hashes containing 3 columns to submit
  New-NexosisDataSet -dataSetName 'new-data' -data `
	@(
		@{
			timestamp = "2013-01-01T00:00:00+00:00"
			sales = "1500.56"
			transactions = "195.0"
		}
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

  .Example
  # Submit a dataset with a data array object and a columns metadata hashtable
  New-NexosisDataSet -dataSetName 'new-data' -data `
	@(
		@{
			timestamp = "2013-01-01T00:00:00+00:00"
			sales = "1500.56"
			transactions = "195.0"
		}
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
	) `
	-columnMetaData `
	@{
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
#>[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$True)]
		[string]$dataSetName,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		$data,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		$columnMetaData
	)
	process {

		if (($null -ne $data) -and ($data -isnot [System.Array])) {
		    throw "Parameter '-data' must be an array of hashes."
		}

		if ($null -ne $columnMetaData -and $columnMetaData -isnot [Hashtable])
		{
			throw "Parameter '-columnMetaData' must be a hashtable of column metadata for the data."	
		}

		if($null -ne $data) {
			# Construct the object to send to the REST endpoint
			$dataSet = @{
				dataSetName = $dataSetName
				columns = $columnMetaData
				data =@(
					$data
				)
			}
		} else {
			# Construct the object to send to the REST endpoint
			$dataSet = @{
				dataSetName = $dataSetName
				columns = $columnMetaData
			}
		}

		if ($dataSetName.Trim().Length -eq 0) { 
			throw "Argument '-DataSetName' cannot be null or empty."
		}

		if ($pscmdlet.ShouldProcess($dataSetName)) {
			Invoke-Http -method Put -path "data/$dataSetName" -Body ($dataSet | ConvertTo-Json -depth 6)
		}
	}
}