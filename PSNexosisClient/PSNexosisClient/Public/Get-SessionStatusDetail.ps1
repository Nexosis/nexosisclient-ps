Function Get-SessionStatusDetail {
<# 
 .Synopsis
  Retrieves the Details of the session status including the current status.

 .Description
  

 .Parameter SessionId
  A Session identifier (UUID) of the session to retrieve

 .Example
  # Get additional detail about the status of a session
  Get-SessionStatusDetail -SessionID 015da45b-2ee7-4a63-b6c7-2f3798ea70a2
#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [GUID]$SessionId
	)
    process {
        Invoke-Http -method Get -path "sessions/$SessionId"
    }
}