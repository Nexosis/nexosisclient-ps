Function New-DataSet {
<# 
 .Synopsis
  This operation creates a new dataset or updates an existing dataset using data from a PSCustomObject.

 .Description
  This operation creates a new dataset using data from a PSCustomObject. If the dataset already 
  exists, adds rows to the dataset. If the specified data contains records with timestamps that
  already exist in the dataset, those records will be overwritten.

 .Parameter DataSetName
  Name of the dataset to create or which to add data
  
 .Parameter DataSet  
  A PSCustom Object used to create the dataset.

 .Example
  # create a new dataset using the contents of the CSV file
  TODO

#>[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$True)]
		[string]$dataSetName,
		#[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		#$dataSet
		[Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		$data,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		$columnMetaData
	)
	process {

		if ($data -isnot [System.Array]) {
		    throw "Parameter '-data' must be an array of hashes."
		}

		if ($null -ne $columnMetaData -and $columnMetaData -isnot [Hashtable])
		{
			throw "Parameter '-columnMetaData' must be a hashtable of column metadata for the data."	
		}

		$dataSet = @{
			dataSetName = $dataSetName
			columns = $columnMetaData
			data =@(
				$data
			)
		}

		Write-Verbose $dataSet

		#if ($null -eq $dataSet)
		#{
		#	throw "You must specify object '-DataSet' to create a dataset."
		#}

		if ($dataSetName.Trim().Length -eq 0) { 
			throw "Argument '-DataSetName' cannot be null or empty."
		}

		if ($pscmdlet.ShouldProcess($dataSetName)) {
			Invoke-Http -method Put -path "data/$dataSetName" -Body ($dataSet | ConvertTo-Json -depth 6)
		}
	}
}