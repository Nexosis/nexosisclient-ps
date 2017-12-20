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
     
     .Parameter PredictionDomain
      Type of prediction the built model is intended to make. Supports Regression or Classification. 
      
      Regression models are used to predict a target (dependent) variable from one or more feature (independent) 
      variables. Regression models always require at least one feature column, and since the output of a 
      regression model is a continuous value, these models can only be used to predict numeric targets.

      Classification models are used to predict which of a discrete set of classes a given record represents. 
      Like regression models, classification models predict a target (dependent) variable from one or more
      feature (independent) variables, and they require at least one feature column. Unlike regression models, 
      the target column of a classification model can be any data type. (The target should contain relatively 
      few distinct values, or classes, to predict.) By default, the Nexosis API will balance the data source 
      used to build a classification model. That is, if 90% of the records in the data source have class A
      and 10% have class B, the API will strive to generate a model that is equally proficient at identifying
      both class A and class B records. To override this, include the switch '-allowUnbalancedData' to the call.
     
     .Parameter callbackUrl
      The Webhook url that will receive updates when the Session status changes
      If you provide a callback url, your response will contain a header named Nexosis-Webhook-Token.  You will receive this
      same header in the request message to your Webhook, which you can use to validate that the message came from Nexosis.
    
     .Parameter allowUnbalancedData
      For Classification Only: If allowUnbalancedData is provided, the API will not seek to balance the data source, which 
      may result in a model better at predicting class A than class B. Defaults to True if not provided.

     .Example
      # Start a session to Build a model using the dataSource housePrices that can later be used to predict house prices.
      Start-NexosisModelSession -dataSourceName 'housingData' -targetColumn 'salePrice' -predictionDomain Regression

     .Example
      # Start a session to Build a model using the dataSource housePrices that can later be used to predict house prices.
      Start-NexosisModelSession -dataSourceName 'csgo' -targetColumn 'VACBanned' -predictionDomain Classification
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
            [switch]$allowUnbalancedData
        )
        process {
            if (($dataSourceName -eq $null ) -or ($dataSourceName.Trim().Length -eq 0)) { 
                throw "Argument '-DataSourceName' cannot be null or empty."
            }

            if ($columnMetadata -isnot [Hashtable])
            {
                throw "Parameter '-ColumnMetaData' must be a hashtable of columns metadata for the data."	
            }

            if ($allowUnbalancedData.IsPresent -and $predictionDomain -ne [PredictionDomain]::Classification) {
                throw "Switch -allowUnbalancedData can only be used for Classification, not Regression."
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
            
            if ($allowUnbalancedData.IsPresent) {
                $createModelObj['extraParameters'] = @{
                    balance = $false
                }
            }

            if ($pscmdlet.ShouldProcess($dataSourceName)) {
    
                if ($pscmdlet.ShouldProcess($dataSourceName)) {       
                    $response = Invoke-Http -method Post -path "sessions/model" -Body ($createModelObj | ConvertTo-Json -depth 6) -needHeaders
                    $responseObj = $response.Content | ConvertFrom-Json
                    $responseObj
                  }
            }
        }   
    }