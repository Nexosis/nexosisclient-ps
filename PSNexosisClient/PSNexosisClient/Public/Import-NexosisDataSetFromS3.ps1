Function Import-NexosisDataSetFromS3 {
<# 
 .Synopsis
  This operation creates a new dataset or updates an existing dataset using data from a CSV File. 
  Import data into Axon from a file on S3

 .Description
 Import data into Axon from a file on S3
  
 .Parameter dataSetName
 The name of the DataSet into which the data should be imported  

 .Parameter S3BucketName
  The AWS Bucket containing the file to be imported
  
 .Parameter S3BucketPath
  The Path in S3 to the file to be imported

 .Parameter S3Region
  The AWS Region in which the S3 bucket is located.

 .Parameter AccessKeyId
 The AWS Access Key ID to use when authenticating the file request. Optional if the file is public.
 
 .Parameter SecretAccessKey
 The AWS Secret Access Key to use when authenticating the file request. Optional if the file is public.

 .Parameter ImportContentType
 The type of content to import (json or csv). Optional. Nexosis will automatically attempt to figure out the type of content if not provided.

 .Parameter Columns
  Metadata about each column in the dataset

 .Example
  # Import a CSV into the data set name 'salesdata' located in S3 given the S3 Bucket path and region.
 Import-NexosisDataSetFromS3 -dataSetName 'salesdata' -S3BucketName 'nexosis-sample-data' -S3BucketPath 'LocationA.csv' -S3Region 'us-east-1'
  
#>[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [string]$dataSetName,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$S3BucketName,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$S3BucketPath,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$S3Region,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        $accessKeyId,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        $secretAccessKey,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ImportContentType]$contentType,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        $columns=$null
	)

	if ($dataSetName.Trim().Length -eq 0) { 
		throw "Argument '-dataSetName' cannot be null or empty."
    }
    if ($S3BucketName.Trim().Length -eq 0) { 
		throw "Argument '-S3BucketName' cannot be null or empty."
	}
    if ($S3BucketPath.Trim().Length -eq 0) { 
		throw "Argument '-S3BucketPath' cannot be null or empty."
	}
    if ($S3Region.Trim().Length -eq 0) { 
		throw "Argument '-S3Region' cannot be null or empty."
	}

    $importS3Data = @{  
        dataSetName = $dataSetName
        bucket = $S3BucketName
        path = $S3BucketPath
        region = $S3Region
    }

    if (($null -ne $accessKeyId) -and ($accessKeyId.Trim().Length -gt 0)) {
        $importS3Data.Add('accessKeyId', $accessKeyId)
    }
    
    if (($null -ne $secretAccessKey) -and ($secretAccessKey.Trim().Length -gt 0)) {
        $importS3Data.Add('secretAccessKey', $secretAccessKey)
    }

    if ($null -ne $contentType) {
        $importAzureData.Add('contentType', [string]$contentType)
    }
    
    if ($null -ne $columns) {
        $importS3Data['columns'] = $columns
    }

    if ($pscmdlet.ShouldProcess($dataSetName)) {
        Invoke-Http -method Post -path "imports/S3" -Body ($importS3Data | ConvertTo-Json -Depth 6)
    }
}
