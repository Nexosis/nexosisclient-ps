Function Get-NexosisImport {
<# 
 .Synopsis
  Lists imports that have been created.

 .Description
  Gets the list of imports that have been created for the company associated with your account.
 
 .Parameter importId
  Retrieves import by ImportId. This option cannot be used with any other. 

 .Parameter dataSetName
  Limits imports to those for a particular dataset. This option cannot be used with the ImportId parameter.

 .Parameter Page
  Format - int32. Zero-based page number of imports to retrieve (default page 0)
	
 .Parameter PageSize
  Format - int32. Count of imports to retrieve in each page (default 100; max 1000)

 .Example
  # Get all imports
  Get-NexosisImport

 .Example
 # Get Import by Import ID
 Get-NexosisImport -ImportId 015d7a16-8b2b-4c9c-865d-9a400e01a291

 .Example
  # Get all imports for DataSet named 'SalesData' 
  Get-NexosisImport -DataSetName 'SalesData'
  
 .Example
  # Get first page and one result of imports for dataset named 'SalesData' 
  Get-NexosisImport -dateSetName 'SalesData' -page 0 -pageSize 20

 .Example
  # Get all imports requested after the date 2017-07-25 UTC
  Get-NexosisImport -requestedAfterDate 2017-07-25+00:00

 .Example
  # Get all datasets that match the partial name 'Location' and Get all associated Imports
  ((Get-NexosisDataSet -partialName 'Location') | Foreach { $_.DataSetName } | Get-NexosisImport)
  
#>[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false, ValueFromPipeline=$True)]
		[Guid]$importId,
		[Parameter(Mandatory=$false, ValueFromPipeline=$True)]
		[string]$dataSetName,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		[DateTime]$requestedAfterDate,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		[DateTime]$requestedBeforeDate,
		[Parameter(Mandatory=$false)]
		[int]$page=0,
		[Parameter(Mandatory=$false)]
		[int]$pageSize=$script:PSNexosisVars.DefaultPageSize
	)
	process {
		if ($importId -eq $null) {			
			if ($page -lt 0) {
				throw "Parameter '-page' must be an integer greater than or equal to 0."
			}

			if (($pageSize -gt ($script:MaxPageSize)) -or ($pageSize -lt 1)) {
				throw "Parameter '-pageSize' must be an integer between 1 and $script:MaxPageSize."
			}
			
			$params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

			if ($dataSetName -ne $null) { 
				$params['dataSetName'] = $dataSetName
			}
			if ($requestedAfterDate -ne $null) { 
				$params['requestedAfterDate'] = $requestedAfterDate
			}
			if ($requestedBeforeDate -ne $null) {
				$params['requestedBeforeDate'] = $requestedBeforeDate
			}
			if ($page -ne 0) {
				$params['page'] = $page
			}
			if ($pageSize -ne ($script:PSNexosisVars.DefaultPageSize)) {
				$params['pageSize'] = $pageSize
			} elseif ($script:PSNexosisVars.DefaultPageSize -ne $script:ServerDefaultPageSize) {
				$params['pageSize'] = $script:PSNexosisVars.DefaultPageSize
			}	

			$response = Invoke-Http -method Get -path 'imports' -params $params    
			$hasResponseCode = $null -ne $response.StatusCode
			
			if ($hasResponseCode -eq $true) {
				$response
			} else {
				$response.items
			}
		} else {
			if (
                $dataSetName.Length -gt 0 -or
                $requestedAfterDate -ne $null -or
                $requestedBeforeDate -ne $null
            ) {
                throw "Parameter '-SessionID' is exclusive and cannot be used with any other parameters."
            }
			Invoke-Http -method Get -path "imports/$importId"
		}
	}
}