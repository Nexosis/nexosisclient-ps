Function Start-NexosisModelSession {
    <# 
     .Synopsis
      Queues a new model-building session to run
    
     .Description
      Model-building sessions are used to build regression and classification models for later use. To build a model, 
      specify the data source to model and the type of model to build. Once the model is built, use the various model
      endpoints to interact with it and generate predictions.

      The type of model to build is determined by the predictionDomain property on the request. Acceptable values 
      are:
        * regression: Builds a regression model
        * classification: Builds a classification model
        * anomalies: Builds an anomaly detection model

     .Parameter dataSourceName
      Name of the dataset or view from which to generate a model
     
     .Parameter targetColumn
     Column in the specified data source to predict with the generated model
     
     .Parameter PredictionDomain
      Type of prediction the built model is intended to make. Supports Regression, Classification 
      and Anomaly Detection.
      
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
     
      Anomaly detection models are used to detect outliers in a dataset. Unlike other model types, anomaly detection
      models are built on unlabeled data, that is, data without known target values. (If you know which rows in your 
      dataset are anomalies and which rows are not, build a classification model instead.) When building an anomaly
      detection model, you should not specify a target column that is in your dataset. Instead, specify the name of
      the column in which you want the results placed. If you don't specify a target column, a column named anomaly 
      will be used to store prediction results.
     
     .Parameter callbackUrl
      The Webhook url that will receive updates when the Session status changes
      If you provide a callback url, your response will contain a header named Nexosis-Webhook-Token.  You will receive this
      same header in the request message to your Webhook, which you can use to validate that the message came from Nexosis.
    
     .Parameter allowUnbalancedData
      For Classification Only: If allowUnbalancedData is provided, the API will not seek to balance the data source, which 
      may result in a model better at predicting class A than class B. Defaults to True if not provided.
     
     .Parameter containsAnomalies
      For Anomaly Detection Only: Nexosis uses one of two different algorithms to build an anomaly detection model on 
      your dataset. By default, we assume that your dataset contains some anomalies. If you are certain that your dataset
      does not contain anomalies (it's from a known good source, for instance), you can specify as such. Set the 
      containsAnomalies property to false and Nexosis will use an algorithm optimized for this sort of dataset to build 
      a model.

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
            [switch]$allowUnbalancedData,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            [switch]$containsAnomalies
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
                throw "Switch -allowUnbalancedData can only be used for Classification, not Regression or Anomalies."
            }

            if ($containsAnomalies.IsPresent -and $predictionDomain -ne [PredictionDomain]::Anomalies) {
                throw "Switch -containsAnomalies can only be used for Anomalies, not Regression or Classification."
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

             if ($containsAnomalies.IsPresent) {
                $createModelObj['extraParameters'] = @{
                    containsAnomalies = $true
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