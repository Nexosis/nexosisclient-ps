Function Get-ViewData {
    <# 
     .Synopsis
      Reads the data in a particular view and returns it as an object.
    
     .Description
      Returns all of the data stored in a dataset. If the DataSet does not exist or an error occurs, it will return 
      an object containing the REST Status Code along with Error details.
    
     .Parameter ViewName
      Name of the view definition for which to retrieve data
    
     .Parameter StartDate  
      Format - date-time (as date-time in ISO8601). Limits results to those on or after the specified date
    
     .Parameter EndDate 
      Format - date-time (as date-time in ISO8601). Limits results to those on or before the specified date
    
     .Parameter Page
      Zero-based page number of results to retrieve.
    
     .Parameter PageSize
      Count of Data rows to retrieve in each page (default 100, max 1000).
     
     .Parameter Include 
     Limits results to the specified columns
    
      .Link
      http://docs.nexosis.com/clients/powershell
    
     .Example
      # Read the data in the view named 'salesdata'
      Get-ViewData -viewName 'salesView'   
     
      .Example 
      # Return the data from view 'salesView'
      (Get-ViewData -viewName 'salesView').Data
      
      .Example
      # Get the data in the view named 'salesview' starting at page 0 and include 1000 records between the provided start date and enddate.
      Get-ViewData -viewName 'salesview' -page 0 -pageSize 1000 -startDate 2017-02-25 -endDate 2017-03-25
    
     .Example
      # Read up to 1000 records in from view S'salesview'
      Get-ViewData -viewName 'salesview' -page 0 -pageSize 1000 
    
     .Example
      # Return the data from view named `new-view` and only include columns timestamp and sales.
      (Get-ViewData -viewName 'new-view' -include timestamp,sales).data
    
     .Example
      # Read the data in the view named 'salesdata' and convert it to JSON at a dept of 4
      Get-ViewData -viewName 'salesview' | ConvertTo-Json -Depth 4

    .Example
    (Get-ViewData 'salesTransactionsWithPromoView').data

    sales   transactions isPromo timestamp                   
    -----   ------------ ------- ---------                   
    1500.56 195          0       2013-01-01T00:00:00.0000000Z
    4078.52 696          0       2013-01-02T00:00:00.0000000Z
    4545.69 743          1       2013-01-03T00:00:00.0000000Z
    4872.63 797          1       2013-01-04T00:00:00.0000000Z
    2420.81 367          0       2013-01-05T00:00:00.0000000Z
    #>[CmdletBinding()]
        Param(
            [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
            [string]$viewName,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            [DateTime]$startDate,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            [DateTime]$endDate,
            [Parameter(Mandatory=$false)]
            [int]$page=0,
            [Parameter(Mandatory=$false)]
            [int]$pageSize=$script:PSNexosisVars.DefaultPageSize,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            $include=@()
        )
        process {
            $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    
            if ($viewName.Trim().Length -eq 0) { 
                throw "Argument '-viewName' cannot be null or empty."
            }
    
            if ($page -lt 0) {
                throw "Parameter '-page' must be an integer greater than 0."
            }
    
            if (($pageSize -gt ($script:MaxPageSize)) -or ($pageSize -lt 1)) {
                throw "Parameter '-pageSize' must be an integer between 1 and $script:MaxPageSize."
            }
            
            if ($null -ne $startDate ) { 
                $params['startDate'] = $startDate
            }
    
            if ($null -ne $endDate) {
                $params['endDate'] = $endDate
            }
    
            if ($page -ne 0) {
                $params['page'] = $page
            }
    
            if ($pageSize -ne ($script:PSNexosisVars.DefaultPageSize)) {
                $params['pageSize'] = $pageSize
            } elseif ($script:PSNexosisVars.DefaultPageSize -ne $script:ServerDefaultPageSize) {
                $params['pageSize'] = $script:PSNexosisVars.DefaultPageSize
            }    
    
            foreach ($val in  $include) {
                $params.Add('include', $val)
            }
                
            Invoke-Http -method Get -path "views/$viewName" -params $params
        }
    }
    