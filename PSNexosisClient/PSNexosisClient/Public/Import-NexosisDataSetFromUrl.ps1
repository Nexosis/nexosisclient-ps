Function Import-NexosisDataSetFromUrl {
<# 
 .Synopsis
  This operation creates a new dataset or updates an existing dataset using data from a CSV File. 
  Import data into Axon from a file at the given URL.

 .Description
  Urls can return either CSV or JSON content (see http://docs.nexosis.com/guides/importingdata for details on supported formats)

  If importing an S3 file in a public bucket, you can also send the url to that file in this parameter.
  
 .Parameter dataSetName
  The name of the DataSet into which the data should be imported  
 
 .Parameter Url
  A valid Cloud Storage Account Connection string.

 .Parameter Auth
  Credentials used for Basic Authentication. Optional.

 .Parameter ImportContentType
  The type of content to import (json or csv). Optional. Nexosis will automatically attempt to figure out the type of content if not provided.

 .Parameter Columns
  Metadata about each column in the dataset

 .Example
  # Import a CSV into the data set name 'salesdata' located in Azure Blob storage given the Azure connection string, container, and blob.
  Import-NexosisDataSetFromUrl -dataSetName 'salesdata' -url 'https://example.com/data/somepayload.csv'
  
#>[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [string]$dataSetName,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$url,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$auth,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ImportContentType]$contentType,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        $columns=$null
	)

	if ($dataSetName.Trim().Length -eq 0) { 
		throw "Argument '-dataSetName' cannot be null or empty."
    }
    if ($url.Trim().Length -eq 0) { 
		throw "Argument '-url' cannot be null or empty."
	}

    $importUrlData = @{  
        dataSetName = $dataSetName
        url = $url
    }

    if ($contentType -ne $null) {
        $importUrlData['contentType'] = [string]$contentType
    }

    if ($null -ne $columns) {
        $importUrlData['columns'] = $columns
    }

    if (($null -ne $auth) -and ($auth.Trim().Length -ne 0)) {
        $importUrlData['auth'] = $auth
    }

    if ($pscmdlet.ShouldProcess($dataSetName)) {
        Invoke-Http -method Post -path "imports/Url" -Body ($importUrlData | ConvertTo-Json -Depth 6)
    }
}
