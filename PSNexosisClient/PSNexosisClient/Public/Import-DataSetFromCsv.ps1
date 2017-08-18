Function Import-DataSetFromCsv {
<# 
 .Synopsis
  This operation creates a new dataset or updates an existing dataset using data from a CSV File.

 .Description
 This operation creates a new dataset using data from a CSV File. If the dataset already exists,
 adds rows to the dataset. If the specified data contains records with timestamps that already
 exist in the dataset, those records will be overwritten.

 .Parameter DataSet
  Name of the dataset to create or which to add data.

 .Parameter CsvFilePath
 The path on disk to a CSV File (CRLF line endings only).

 .Example 
  # Submit a dataset using the contents of the specified CSV File.
  Import-DataSetFromCsv -dataSetName 'ps-csvimport' -csvFilePath "C:\path\to\sample.csv"
  
#>[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
		[string]$dataSetName,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		$csvFilePath
	)
	process {
		if ($dataSetName.Trim().Length -eq 0) { 
			throw "Argument '-dataSetName' cannot be null or empty."
		}

		if (($null -ne $csvFilePath) -and ($csvFilePath.Trim().Length -gt 0)) {
			if (Test-Path $csvFilePath) {
				if ($pscmdlet.ShouldProcess($dataSetName)) {
					Invoke-Http -method Put -path "data/$dataSetName" -FileName $csvFilePath -contentType "text/csv"
				}
			} else {
				throw "File $csvFilePath doesn't exist."
			}
		}
	}
}