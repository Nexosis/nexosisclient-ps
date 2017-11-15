Function Start-NexosisImpactSession {
<# 
 .Synopsis
  Start an impact session for a data source using the Target Column, 
  Columns Meta-data, and a date range to determine the impact.

 .Description
  Impact sessions are used to determine the impact of a particular event on a
  data source . For example, a sale at a restaurant may impact daily sales or customer
  counts. To create an impact session, specify the data source for which to determine
  impact, as well as the start and end dates of the impactful event. The Nexosis 
  API will execute a series of machine learning algorithms to determine the impact 
  of the event on the data source.
  
  Both the start and end dates for the impact session must always be on or before
  the timeStamp of the last record in your data source.
 
  .Parameter dataSourceName
   Name of the data source (view, dataset, etc) to forecast

  .Parameter targetColumn
   Column in the specified data source  to forecast

  .Parameter eventName 
   Name of the event for which to determine impact

  .Parameter resultInterval
   Defaults to Day. The interval at which predictions should be generated. Possible 
   values are Hour, Day, Week, Month, and Year. 

  .Parameter startDate
   First date to forecast date-time formatted as date-time in ISO8601.

  .Parameter endDate
   Last date to forecast date-time formatted as date-time in ISO8601.

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
 # Start a new Impact Session using the data source 'salesdata' and give it the event name 'promo-impact'. Build a daily forcast on target
 column 'sales' between the dates of 01-03-2013 through 01-04-2013
 Start-NexosisImpactSession -dataSourceName 'salesdata' -eventName 'promo-impact' -targetColumn 'sales' -startDate 2013-01-03 -endDate 2013-01-04 -resultInterval Day
#>[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [string]$dataSourceName,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$targetColumn,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$eventName,
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
      $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

      if ($dataSourceName.Trim().Length -eq 0) { 
        throw "Argument '-DataSourceName' cannot be null or empty."
      }
      
      $params['dataSourceName'] = $dataSourceName

      if (($null -ne $targetColumn) -and ($targetColumn.Trim().Length -ne 0)) {
        $params['targetColumn'] = $targetColumn
      }

      if ($eventName.Trim().Length > 0) {
        $params['eventName'] = $eventName
      }

      if ($null -ne $startDate) { 
        $params['startDate'] = $startDate
      }
      if ($null -ne $endDate) {
        $params['endDate'] = $endDate
      }
      
      if ($callbackUrl.Trim().Length > 0){
        $params['callbackUrl'] = $callbackUrl
      }

      if ($isEstimate) {
          $params['isEstimate'] = $isEstimate.ToString().ToLowerInvariant()
      }
      
      $params['resultInterval'] = $resultInterval.toString()
            
      if ($pscmdlet.ShouldProcess($dataSourceName)) {       
          $response = Invoke-Http -method Post -path "sessions/impact" -Body ($columnMetadata | ConvertTo-Json -depth 6) -params $params -ContentType 'application/json' -needHeaders
          $responseObj = $response.Content | ConvertFrom-Json
          if ($response.Headers.ContainsKey('Nexosis-Request-Cost')) {
            # Add additional field called 'costEstimate' to the return object
            $responseObj | Add-Member -name "costEstimate" -value $response.Headers['Nexosis-Request-Cost'] -MemberType NoteProperty
          }
          $responseObj
        }
    }
}