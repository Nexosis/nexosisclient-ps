Function Get-SessionResult {
<# 
 .Synopsis
  Gets the forecast or impact results of a particular session

 .Description
  In addition to the response body indicating information about the session, the response to this endpoint adds a nexosis-session-status HTTP response header indicating the completion status of the session.

    Forecast session results consist of the predictions for the dates specified when the session was created.

    Impact session results consist of the predictions of what would have happened over the specified date range, had the impactful event not occurred. Impact session results also include metrics that describe the overall impact of the event on the dataset. These metrics are:
       * pValue: Statistical value used to determine the significance of the impact. A small p-value indicates strong evidence of impact, whereas a p-value approaching 0.5 indicates weak evidence of impact.
       * absoluteEffect: Total absolute effect of the event on the dataset. Answers the question, "How much did this event affect my dataset?"
       * relativeEffect: Percentage effect of the event on the dataset. Answers the question, "By what percentage did this event affect my dataset?"  

 .Parameter SessionId
  A Session identifier (UUID) of the session results to retrieve.

 .Example

#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [GUID]$SessionId
	)
    process {
        Invoke-Http -method Get -path "sessions/$SessionId/results"
    }
}