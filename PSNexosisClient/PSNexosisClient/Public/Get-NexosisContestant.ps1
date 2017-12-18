Function Get-NexosisContestant {
<# 
 .Synopsis
  Gets all the contestant algorithms which were executed for the given contest.

 .Description
  Gets all the contestant algorithms which were executed for the given contest.

  Note: This endpoint is not available under the community plan. Please upgrade to a paid plan 
  if you are currently on Community. Be sure to use the Paid Subscription key if you have already 
  upgraded.

 .Parameter SessionId
  A Session identifier (UUID) of the session contest contestants to retrieve.

 .Example
  # Return just the contestants from the contest run for the given serssion
  Get-NexosisContestant -SessionId 015df24f-7f43-4efe-b8ba-1e28d67eb3fa

#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [GUID]$SessionId,
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        [GUID]$contestandId,
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        $predictionInterval,
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        $page,
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        $pageSize
	)
    process {
        if ($contestandId -ne $null) {
            $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        
            # Paging only works with contestandId
             if ($page -ne $null) {
                if ($page -lt 0) {
                    throw "Parameter '-page' must be an integer greater than or equal to 0."
                }

                if (($pageSize -gt ($script:MaxPageSize)) -or ($pageSize -lt 1)) {
                    throw "Parameter '-pageSize' must be an integer between 1 and $script:MaxPageSize."
                }

                if ($page -ne 0) {
                    $params['page'] = $page
                }

                if ($pageSize -ne ($script:PSNexosisVars.DefaultPageSize)) {
                    $params['pageSize'] = $pageSize
                } elseif ($script:PSNexosisVars.DefaultPageSize -ne $script:ServerDefaultPageSize) {
                    $params['pageSize'] = $script:PSNexosisVars.DefaultPageSize
                }
            }
            if ($predictionInterval -ne $null) {
                $params['predictionInterval'] = $predictionInterval
            }

            Invoke-Http -method Get -path "sessions/$SessionId/contest/contestants/$contestandId" -params $params
        } else {
             if (
                $page.Length -gt 0 -or
                $page.Length -ne $null -or
                $pageSize -ne $null -or
                $predictionInterval -ne $null
            ) {
                throw "Parameter '-sessionId' cannot be used with 'page', 'pageSize', or 'predictionInterval' unless providing '-contestentId'."
            }
            
            $results = Invoke-Http -method Get -path "sessions/$SessionId/contest/contestants"
            $results.items
        }
    }
}