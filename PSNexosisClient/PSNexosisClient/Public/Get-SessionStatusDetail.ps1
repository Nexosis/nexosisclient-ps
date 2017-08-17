Function Get-SessionStatusDetail {
<# 
 .Synopsis
  The response to this endpoint adds a nexosis-session-status HTTP response header indicating the completion status of the session.

 .Description
  The response to this endpoint adds a nexosis-session-status HTTP response header indicating the completion status of the session.

 .Parameter SessionId
  A Session identifier (UUID) of the session to retrieve

 .Example
  #
  Get-SessionStatus -SessionID 015da45b-2ee7-4a63-b6c7-2f3798ea70a2   
#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [GUID]$SessionId
	)
    process {
        Invoke-Http -method Get -path "sessions/$SessionId"
    }
}