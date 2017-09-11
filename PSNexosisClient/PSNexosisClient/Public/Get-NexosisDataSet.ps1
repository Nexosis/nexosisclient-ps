Function Get-NexosisDataSet {
<# 
 .Synopsis
  Gets the list of all datasets that have been saved to the system.

 .Description
  Returns a list of all the stored datasets and related data.

 .Parameter PartialName
  Limits results to only those datasets with names containing the specified value

 .Parameter Page
  Zero-based page number of results to retrieve.

 .Parameter PageSize
  Count of datasets to retrieve in each page (default 100, max 1000).

 .Link
  http://docs.nexosis.com/clients/powershell

 .Example
  # Get a list of datasets that have the world 'sales' in the dataset name
  Get-NexosisDataSet -partialName 'sales'

 .Example
  # Get a list of datasets, convert it to Json
  Get-NexosisDataSet -page 0 -pageSize 2 | ConvertTo-Json -Depth 4

  .Example
   # Get page 0 of datasets that have the world 'sales' in the dataset name, with a max of 20 for this page
   Get-NexosisDataSet -partialName 'sales' -page 0 -pageSize 20
#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
		[string]$partialName=$null,
		[Parameter(Mandatory=$false)]
		[int]$page=0,
		[Parameter(Mandatory=$false)]
        [int]$pageSize=$script:PSNexosisVars.DefaultPageSize
	)
    process {
        if ($page -lt 0) {
            throw "Parameter '-page' must be an integer greater than or equal to 0."
        }

        if (($pageSize -gt ($script:MaxPageSize)) -or ($pageSize -lt 1)) {
            throw "Parameter '-pageSize' must be an integer between 1 and $script:MaxPageSize."
        }

        $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        if ($partialName.Trim().Length -gt 0) { 
            $params['partialName'] = $partialName
        }

        if ($page -ne 0) {
            $params['page'] = $page
        }

        if ($pageSize -ne ($script:PSNexosisVars.DefaultPageSize)) {
            $params['pageSize'] = $pageSize
        } elseif ($script:PSNexosisVars.DefaultPageSize -ne $script:ServerDefaultPageSize) {
            $params['pageSize'] = $script:PSNexosisVars.DefaultPageSize
        }

        $response = Invoke-Http -method Get -path 'data' -params $params
        $response.items
    }
}