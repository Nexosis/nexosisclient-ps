Function Get-NexosisContestSelection {
<# 
 .Synopsis
  Gets the selection criteria that is used to determined which algorithms were executed.

 .Description
  The metricSets contain some information about the data source that was used by the session. It includes some basic 
  stats about the dataset, such as the mean and standard deviation. For a forecast or impact session, it will also
  include information about what levels of seasonality were detected in the data.
  
  Note: This endpoint is not available under the community plan. Please upgrade to a paid plan if you are currently
  on Community. Be sure to use the Paid Subscription key if you have already upgraded.

 .Parameter SessionId
  A Session identifier (UUID) of the session contest contestants to retrieve.

 .Example
  # Return just the contestants from the contest run for the given serssion
  Get-NexosisContestSelection -SessionId 015df24f-7f43-4efe-b8ba-1e28d67eb3fa

#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [GUID]$SessionId
	)
    process {
        $encodedSessionId = [uri]::EscapeDataString($SessionId)
        Invoke-Http -method Get -path "sessions/$encodedSessionId/contest/selection"
    }
}