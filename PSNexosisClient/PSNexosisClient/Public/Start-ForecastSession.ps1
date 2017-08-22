Function Start-ForecastSession {
<# 
 .Synopsis
  Start a forecast session for a submitted data source using the Target Column, 
  Columns Meta-data, and a range to forecast.

 .Description
  Forecast sessions are used to predict future values for a data source. To create a
  forecast session, specify the data source to forecast, as well as the start and end
  dates of the forecast period. The Nexosis API will execute a series of machine
  learning algorithms to approximate future values for the data source.

  The forecast start date should be on the same day as (or before) the last date
  in the data source. If there is a gap between your forecast start date and the date 
  of the last record in your data set, the Nexosis API will behave as if there is 
  no gap.   

  .Parameter dataSourceName
   Name of the data source (view, dataset, etc) to forecast

  .Parameter targetColumn
   Column in the specified data source to forecast

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
  # Start a Daily Forecast session on the data source 'salesdata' and set the target column to forecast to
  'sales' - forecast between the range of 01-06-2013 to 01-13-2013
  Start-ForecastSession -dataSourceName 'salesdata' -targetColumn 'sales' -startDate 2013-01-06 -endDate 2013-01-13 -resultInterval Day -columnMetadata $columns
#>[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [string]$dataSourceName,
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
        $columnMetadata=@{},
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [switch]$isEstimate
    )
    process {
        if (($dataSourceName -eq $null ) -or ($dataSourceName.Trim().Length -eq 0)) { 
            throw "Argument '-DataSourceName' cannot be null or empty."
        }

        if ($columnMetadata -isnot [Hashtable])
		{
			throw "Parameter '-columnMetaData' must be a hashtable of column metadata for the data."	
        }
        $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        
        $params['dataSourceName'] = $dataSourceName
        
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

        if ($pscmdlet.ShouldProcess($dataSourceName)) {
            Invoke-Http -method Post -path "sessions/forecast" -Body ($columnMetadata | ConvertTo-Json -depth 6) -params $params
        }
    }   
}