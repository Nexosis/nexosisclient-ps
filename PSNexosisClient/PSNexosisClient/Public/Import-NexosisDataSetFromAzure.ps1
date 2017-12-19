Function Import-NexosisDataSetFromAzure {
<# 
 .Synopsis
  This operation creates a new dataset or updates an existing dataset using data from a CSV or JSON File. 
  Import data into Axon from a file in Azure Blob Storage.

 .Description
 Import data into Axon from a CSV or JSON file on Azure Blob Storage
  
 .Parameter dataSetName
 The name of the DataSet into which the data should be imported  

 .Parameter connectionString
  A valid Cloud Storage Account Connection string.
  
 .Parameter container
  A string containing the name of the blob container.

 .Parameter blob
  A string containing the name of the blob.

 .Parameter ImportContentType
 The type of content to import (json or csv). Optional. Nexosis will automatically attempt to figure out the type of content if not provided.

 .Parameter Columns
  Metadata about each column in the dataset

 .Example
  # Import a CSV into the data set name 'salesdata' located in Azure Blob storage given the Azure connection string, container, and blob.
  Import-NexosisDataSetFromAzure -dataSetName 'salesdata' -connectionString 'BlobEndpoint=https://myblobendpoint.blob.core.windows.net/' -container 'mycontainer' -blob 'mydatafile.csv'
  
#>[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [string]$dataSetName,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$connectionString,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$container,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$blob,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ImportContentType]$contentType,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        $columns=$null
	)
    
   

	if ($dataSetName.Trim().Length -eq 0) { 
		throw "Argument '-dataSetName' cannot be null or empty."
    }
    if ($null -eq $connectionString -or $connectionString.Trim().Length -eq 0) { 
		throw "Argument '-ConnectionString' cannot be null or empty."
	}
    if ($container.Trim().Length -eq 0) { 
		throw "Argument '-Container' cannot be null or empty."
	}
    if ($blob.Trim().Length -eq 0) { 
		throw "Argument '-Blob' cannot be null or empty."
	}
    
    $importAzureData = @{  
        dataSetName = $dataSetName
        connectionString = $ConnectionString
        container = $container
        blob = $blob
    }

    if ($contentType -ne $null) {
        $importAzureData['contentType'] = [string]$contentType
    }

    if ($null -ne $columns) {
        $importAzureData['columns'] = $columns
    }

    if ($pscmdlet.ShouldProcess($dataSetName)) {
        Invoke-Http -method Post -path "imports/Azure" -Body ($importAzureData | ConvertTo-Json -Depth 6)
    }
}
