Function Remove-Session {
<# 
  .Synopsis
  Delete sessions

 .Description
  Removes Sessions from your account

 .Parameter SessionId
  The Id (UUID) of the session to delete. All other paramters will be ignored.

 .Parameter SessionType
  The type of session to be deleted (Forecast or Impact)

 .Parameter DataSetName
  Name of the dataset from which to remove data.

 .Parameter EventName
  Limits impact sessions to those for a particular event

 .Parameter RequestedAfterDate  
  Limits data removed to those on or after the specified date,  formatted as a date-time in ISO8601.

 .Parameter RequestedBeforeDate 
  Limits data removed to those on or before the specified date, formatted as a date-time in ISO8601.

 .Example

#>[CmdletBinding(SupportsShouldProcess=$true)] 
	Param(
        [Parameter(ValueFromPipeline=$True, Mandatory=$false)]
		[Guid]$sessionId,
        [Parameter(ValueFromPipeline=$True, Mandatory=$false)]
		[string]$sessionType,
        [Parameter(ValueFromPipeline=$True, Mandatory=$false)]
		[string]$dataSetName,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$false)]
		[DateTime]$requestedAfterDate,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$false)]
		[DateTime]$requestedBeforeDate,
		[switch] $Force=$False
	)
	process {
		$params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        
        # Session ID will not be used with other parameters
        if ($sessionId -eq $null) {
            if ($sessionType -ne $null) {
                if (($sessionType.Equals('forecast')) -or ($sessionType.Equals('impact'))) {
                    $params['sessionType'] = $sessionType
                }
                else {
                    throw "Invalid parameter specified for '-SessionType.' Valid options are 'forecast' and 'impact.'"
                }
            }
            
            if ($dataSetName -ne $null) {
                $params['dataSetName'] = $dataSetName
            }

            if ($requestedAfterDate -ne $null) { 
                $params['requestedAfterDate'] = $requestedAfterDate
            }
            
            if ($requestedBeforeDate -ne $null) {
                $params['requestedBeforeDate'] = $requestedBeforeDate
            }

            if ($pscmdlet.ShouldProcess($dataSetName)) {
                if ($Force -or $pscmdlet.ShouldContinue("Are you sure you want to permanently delete the session(s)?'$dataSetName'.", "Confirm Delete?")) {
                    Invoke-Http -method Delete -path "sessions" -params $params
                }
            }
        } else {
            if (
                $sessionType.Length -gt 0 -or
                $dataSetName.Length -gt 0 -or
                $requestedAfterDate -ne $null -or
                $requestedBeforeDate -ne $null
            ) {
                throw "Parameter '-SessionID' is exclusive and cannot be used with any other parameters."
            }
            
            if ($pscmdlet.ShouldProcess($dataSetName)) {
                if ($Force -or $pscmdlet.ShouldContinue("Are you sure you want to permanently delete the session(s)?'$dataSetName'.", "Confirm Delete?")) {
                    Invoke-Http -method Delete -path "sessions/$sessionId"
                }
            }
        }
	}
}
