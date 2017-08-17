Function Get-Import {
<# 
 .Synopsis
  Lists imports that have been created.

 .Description
  Gets the list of imports that have been created for the company associated with your account.
 
 .Parameter dataSetName
  Limits imports to those for a particular dataset

 .Parameter Page
  Format - int32. Zero-based page number of imports to retrieve (default page 0)
	
 .Parameter PageSize
  Format - int32. Count of imports to retrieve in each page (default 100; max 1000)

 .Example
  # Get all imports
  Get-Import

 .Example
  # Get imports for DataSet named 'SalesData'
  Get-Import -DataSetName 'SalesData'
  
 .Example
  # Get first page and one result of imports for dataset named 'SalesData' 
  Get-Import -dateSetName 'SalesData' -page 0 -pageSize 1

 .Example
  # Get all imports requested after the date 2017-07-25 UTC
  Get-Import -requestedAfterDate 2017-07-25T00:00:00Z 

 .Example
  # Get all datasets that match the partial name 'Location' and Get all associated Imports
  ((Get-DataSet -partialName 'Location').items | Foreach { $_.DataSetName } | Get-Import).items
  
#>[CmdletBinding()]
	Param(
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

		if (($page -ge $script:MaxPageSize) -or ($page -lt 0)) {
            throw "Parameter '-page' must be an integer between 0 and $script:MaxPageSize."
        }

        if (($pageSize -ge $script:MaxPageSize) -or ($pageSize -lt 0)) {
            throw "Parameter '-pageSize' must be an integer between 0 and $script:MaxPageSize."
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
		}
		$response = Invoke-Http -method Get -path 'imports' -params $params    
		$hasResponseCode = $null -ne $response.StatusCode
        
        if ($hasResponseCode -eq $true) {
            $response
        } else {
            $response.items
        }
	}
}