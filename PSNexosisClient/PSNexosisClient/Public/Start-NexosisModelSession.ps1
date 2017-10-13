Function Start-NexosisModelSession {
    <# 
     .Synopsis
      Queues a new model-building session to run
    
     .Description
      Queues a new model-building session to run

     .Parameter dataSourceName
      Name of the dataset or view from which to generate a model
     
     .Parameter targetColumn
     Column in the specified data source to predict with the generated model
     
     .Parameter PredictionDomaim
      Type of prediction the built model is intended to make. (Currently the only suppported value is Regression).
     
     .Parameter callbackUrl
      The Webhook url that will receive updates when the Session status changes
      If you provide a callback url, your response will contain a header named Nexosis-Webhook-Token.  You will receive this
      same header in the request message to your Webhook, which you can use to validate that the message came from Nexosis.
    
     .Parameter isEstimate
      If specified, the session will not be processed.  The returned object will be populated with the estimated 
      cost that the request would have incurred.
    
     .Example
      # Start a session to Build a model using the dataSource housePrices that can later be used to predict house prices.
      Start-NexosisModelSession -dataSourceName 'housingData' -targetColumn 'salePrice' -predictionDomain Regression
    #>[CmdletBinding(SupportsShouldProcess=$true)]
        Param(
            [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
            [string]$dataSourceName,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            [string]$targetColumn,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            [PredictionDomain]$predictionDomain=[PredictionDomain]::Regression,
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
                throw "Parameter '-ColumnMetaData' must be a hashtable of columns metadata for the data."	
            }
            
            $createModelObj = @{
                dataSourceName = $dataSourceName
                predictionDomain = $predictionDomain.ToString().ToLower()
            }

            if (($null -ne $columnMetadata) -and ($columnMetadata.ContainsKey("columns"))) {
                $createModelObj['columns'] = $columnMetadata.columns
            }

            if (($null -ne $targetColumn) -and ($targetColumn.Trim().Length -ne 0)) {
                $createModelObj['targetColumn'] = $targetColumn
            }

            if (($null -ne $callbackUrl) -and ($callbackUrl.Trim().Length -ne 0)) {
                $createModelObj['callbackUrl'] = $callbackUrl
            }
            
            if ($isEstimate.IsPresent) {
                $createModelObj['isEstimate'] = $isEstimate.ToString().ToLower()
            }

            if ($pscmdlet.ShouldProcess($dataSourceName)) {
    
                if ($pscmdlet.ShouldProcess($dataSourceName)) {       
                    $response = Invoke-Http -method Post -path "sessions/model" -Body ($createModelObj | ConvertTo-Json -depth 6) -needHeaders
                    $responseObj = $response.Content | ConvertFrom-Json
                    if ($response.Headers.ContainsKey('Nexosis-Request-Cost')) {
                      # Add additional field called 'costEstimate' to the return object
                      $responseObj | Add-Member -name "costEstimate" -value $response.Headers['Nexosis-Request-Cost'] -MemberType NoteProperty
                    }
                    $responseObj
                  }
            }
        }   
    }