Function Get-View {
    <# 
     .Synopsis
      Gets the list of view definitions that have been created
    
     .Description
      Returns a list of View definitions.
    
     .Parameter PartialName
      Limits results to only those view definitions with names containing the specified value
    
      .Parameter DataSetName
      Limits results to only those view definitions that reference the specified dataset
    
     .Parameter Page
      Zero-based page number of results to retrieve.
    
     .Parameter PageSize
      Count of datasets to retrieve in each page (default 100, max 1000).
    
     .Link
      http://docs.nexosis.com/clients/powershell
    
     .Example
      # Get a list of all views
      Get-View 
    
     .Example
      # Get all the Views that have the world 'sales' in the dataset name
      Get-View -dataSetName sales

     .Example
      # Get the first two views and convert it to Json
      Get-View -page 0 -pageSize 2 | ConvertTo-Json -Depth 4
    
      .Example
       # Get page 0 of datasets that have the world 'sales' in the dataset name, with a max of 20 for this page
       Get-DataSet -partialName 'sales' -page 0 -pageSize 20
    #>[CmdletBinding()]
        Param(
            [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
            [string]$partialName=$null,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$True)]
            [string]$dataSetName=$null,
            [Parameter(Mandatory=$false)]
            [int]$page=0,
            [Parameter(Mandatory=$false)]
            [int]$pageSize=$script:PSNexosisVars.DefaultPageSize
        )
        process {
            if ($page -lt 0) {
                throw "Parameter '-page' must be an integer greater than 0."
            }
    
            if (($pageSize -gt ($script:MaxPageSize)) -or ($pageSize -lt 1)) {
                throw "Parameter '-pageSize' must be an integer between 1 and $script:MaxPageSize."
            }
    
            $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    
            if ($partialName.Trim().Length -gt 0) { 
                $params['partialName'] = $partialName
            }

            if ($dataSetName.Trim().Length -gt 0) {
                $params['dataSetName'] = $dataSetName
            }
        
            if ($page -ne 0) {
                $params['page'] = $page
            }
    
            if ($pageSize -ne ($script:PSNexosisVars.DefaultPageSize)) {
                $params['pageSize'] = $pageSize
            }
    
            $response = Invoke-Http -method Get -path 'views' -params $params
            
            $hasResponseCode = $null -ne $response.StatusCode
            
            if ($hasResponseCode -eq $true) {
                $response
            } else {
                $response.items
            }
        }
    }