Function Start-ForecastSession {
<# 
 .Synopsis
  Start a forecast session for a submitted dataset using the Target Column, 
  Columns Meta-data, and a range to forecast.

 .Description
  Forecast sessions are used to predict future values for a dataset. To create a
  forecast session, specify the dataset to forecast, as well as the start and end
  dates of the forecast period. The Nexosis API will execute a series of machine
  learning algorithms to approximate future values for the dataset.

  The forecast start date should be on the same day as (or before) the last date
  in the dataset. If there is a gap between your forecast start date and the date 
  of the last record in your data set, the Nexosis API will behave as if there is 
  no gap.   

  .Parameter dataSetName
   Name of the dataset to forecast

  .Parameter targetColumn
   Column in the specified dataset to forecast

  .Parameter startDate
   First date to forecast date-time formatted as date-time in ISO8601.

  .Parameter endDate
   Last date to forecast date-time formatted as date-time in ISO8601.

  .Parameter resultInterval
   The interval at which predictions should be generated. Possible 
   values are Hour, Day, Week, Month, and Year. Defaults to Day.

  .Parameter callbackUrl
   The Webhook url that will receive updates when the Session status changes
   If you provide a callback url, your response will contain a header named 
   Nexosis-Webhook-Token. You will receive this same header in the request
   message to your Webhook, which you can use to validate that the message 
   came from Nexosis.

  .Parameter isEstimate
   If specified, the session will not be processed. The returned 
   costs will include the estimated cost that the request would have incurred.  

 .Example
  
 .Example
  
#>[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [string]$dataSetName,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$targetColumn,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [DateTime]$startDate,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [DateTime]$endDate,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ResultInterval]$resultInterval=[ResultInterval]::Day,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$callbackUrl,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        $columnsMetadata=@{},
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [switch]$isEstimate
    )
    process {
        if (($dataSetName -eq $null ) -or ($dataSetName.Trim().Length -eq 0)) { 
            throw "Argument '-DataSetName' cannot be null or empty."
        }

        if ($columnsMetadata -isnot [Hashtable])
		{
			throw "Parameter '-columnMetaData' must be a hashtable of column metadata for the data."	
        }
        $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        
        $params['dataSetName'] = $dataSetName
        
        if ($targetColumn -ne $null){
            $params['targetColumn'] = $targetColumn
        } 

        if ($startDate -ne $null) { 
            $params['startDate'] = $startDate
        }
        if ($endDate -ne $null) {
            $params['endDate'] = $endDate
        }

        if ($callbackUrl -ne $null){
            $params['callbackUrl'] = $callbackUrl
        }

        if ($isEstimate) {
            $params['isEstimate'] = $isEstimate.ToString().ToLowerInvariant()
        }

        $params['resultInterval'] = $resultInterval.toString()

        if ($pscmdlet.ShouldProcess($dataSetName)) {
            Invoke-Http -method Post -path "sessions/forecast" -Body ($columnsMetadata | ConvertTo-Json -depth 6) -params $params
        }
    }   
}