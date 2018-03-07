Function Get-NexosisContestChampion {
<# 
 .Synopsis
  Gets the champion of a contest, and the test data used in scoring the algorithm

 .Description
  This is the algorithm which was determined to score the best for the given contest. Scoring metrics, 
  as well as the test data, is returned. 
  
  Note: This endpoint is not available under the community plan. Please upgrade to a paid plan if 
  you are currently on Community. Be sure to use the Paid Subscription key if you have already upgraded.

 .Parameter SessionId
  A Session identifier (UUID) of the session contest contestants to retrieve.

 .Example
  # Return just the contestants from the contest run for the given serssion
  Get-NexosisChampion -SessionId 015df24f-7f43-4efe-b8ba-1e28d67eb3fa
#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [GUID]$SessionId,
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        $predictionInterval,
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        $page,
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        $pageSize
	)
    process {
        $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)    
        if (($null -ne $page) -and ($page -ne 0)) {
            $params['page'] = $page
        }

        if ($null -ne $pageSize) {
             if ($pageSize -ne ($script:PSNexosisVars.DefaultPageSize)) {
                $params['pageSize'] = $pageSize
            } elseif ($script:PSNexosisVars.DefaultPageSize -ne $script:ServerDefaultPageSize) {
                $params['pageSize'] = $script:PSNexosisVars.DefaultPageSize
            }
        }

        if ($null -ne $predictionInterval) {
            $params['predictionInterval'] = $predictionInterval
        }
        $encodedSessionId = [uri]::EscapeDataString($SessionId)
        Invoke-Http -method Get -path "sessions/$encodedSessionId/contest/champion" -params $params
    }
}