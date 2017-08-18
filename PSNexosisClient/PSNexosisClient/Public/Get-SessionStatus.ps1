Function Get-SessionStatus {
<# 
 .Synopsis
  The response to this endpoint adds a nexosis-session-status HTTP response header indicating the completion status of the session.

 .Description
  The response to this endpoint adds a nexosis-session-status HTTP response header indicating the completion status of the session.

 .Parameter SessionId
  A Session identifier (UUID) of the session to retrieve

 .Example
  # Retrieve the session status for the given session ID (Requested, Started, Completed, Failed).
  Get-SessionStatus -SessionID 015da45b-2ee7-4a63-b6c7-2f3798ea70a2

 .Example
 # For each retrieved session for dataset named 'salesdata', get the current status
 (Get-Session -dataSetName salesdata) | foreach { "SessionId: " + $_.SessionID + " Status: " + (Get-SessionStatus $_.SessionId) }
#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [GUID]$SessionId
	)
    process {
        $response = Invoke-Http -method Head -path "sessions/$SessionId"
        $hasResponseCode = $null -ne $response.StatusCode

        if (($hasResponseCode -eq $true) -and ($response.StatusCode -eq 200)) {
            $response.Headers['Nexosis-Session-Status']
        } else {
            $response            
        }
    }
}