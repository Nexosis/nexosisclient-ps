Function Import-NexosisDataSetFromJson {
<# 
 .Synopsis
  This operation creates a new dataset or updates an existing dataset using data from a JSON File.

 .Description
 This operation creates a new dataset using data from a JSON File. If the dataset already exists,
 adds rows to the dataset. If the specified data contains records with timestamps that already
 exist in the dataset, those records will be overwritten. 
 NOTE: The JSON file must be formatted as described in the API Documentation on Adding New DataSet Data.

 .Parameter DataSet
  Name of the dataset to create or which to add data.

 .Parameter JsonFilePath
 The path on disk to a JSON File.

 .Example 
  # Submit a dataset using the contents of the specified JSON File.
  Import-NexosisDataSetFromJson -dataSetName 'ps-jsonimport' -jsonFilePath "C:\path\to\sample.json"
  
#>[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
		[string]$dataSetName,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		$jsonFilePath
	)
	process {
		if ($dataSetName.Trim().Length -eq 0) { 
			throw "Argument '-dataSetName' cannot be null or empty."
		}

		if (($null -ne $jsonFilePath) -and ($jsonFilePath.Trim().Length -gt 0)) {
			if (Test-Path $jsonFilePath) {
				if ($pscmdlet.ShouldProcess($dataSetName)) {
					Invoke-Http -method Put -path "data/$dataSetName" -FileName $jsonFilePath -contentType "application/json"
				}
			} else {
				throw "File $jsonFilePath doesn't exist."
			}
		} else {
            throw "JSON File cannot be null or empty."
        }
	}
}