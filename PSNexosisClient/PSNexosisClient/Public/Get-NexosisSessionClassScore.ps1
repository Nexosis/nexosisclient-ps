Function Get-NexosisSessionClassScore {
<# 
 .Synopsis
  Gets the class scores for each result of a particular completed classification model session

 .Description
  Whereas classification session results indicate the class chosen for each row in the test set,
  this endpoint returns the scores for each possible class for ech row in the test set. Higher scores
  indicate that the model is more confident that the row fits into the specified class, but the scores 
  are not strict probabilities, and they are not comparable across sessions or data sources.

 .Parameter SessionId
  A Session identifier (UUID) of the session results to retrieve.

 .Parameter Page
  Zero-based page number of results to retrieve.

 .Parameter PageSize
  Count of Data rows to retrieve in each page (default 100, max 1000).
 
 .Example
  # Retrieve session data for sesion with the given session ID
  Get-NexosisSessionClassScore -sessionId 015df24f-7f43-4efe-b8ba-1e28d67eb3fa

 .Example
  # Return just the session result data for the given session ID.
  (Get-NexosisSessionClassScore -SessionId 015df24f-7f43-4efe-b8ba-1e28d67eb3fa).data

#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [GUID]$SessionId,
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
        
        if ($page -ne 0) {
			$params['page'] = $page
		}

		if ($pageSize -ne ($script:PSNexosisVars.DefaultPageSize)) {
            $params['pageSize'] = $pageSize
        }  elseif ($script:PSNexosisVars.DefaultPageSize -ne $script:ServerDefaultPageSize) {
            $params['pageSize'] = $script:PSNexosisVars.DefaultPageSize
        }
        Invoke-Http -method Get -path "sessions/$SessionId/results/classscores" -params $params
    }
}