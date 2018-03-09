Function Get-NexosisSessionFeatureImportanceScore {
    <# 
     .Synopsis
      Gets the feature importance scores generated prior to building a model.
    
     .Description
      Feature importance is based on linear and nonlinear correlations between each feature and the target variable. If it is necessary
      to select a subset of features for building the model this score is used to rank features in order of importance.
    
     .Parameter SessionId
      A Session identifier (UUID) of the session results to retrieve.
    
     .Example
      # Retrieve feature importance for sesion with the given session ID
      PS> Get-NexosisSessionFeatureImportanceScore -sessionId 015df24f-7f43-4efe-b8ba-1e28d67eb3fa
    
     .Example
      # Return just the feature importance data for the given session ID.
      PS> (Get-NexosisSessionFeatureImportanceScore -SessionId 016202b8-38d7-439c-8c6a-61e00c3915ee).featureImportance 
    
    #>[CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
            [GUID]$SessionId
        )
        process {
            $encodedSessionId = [uri]::EscapeDataString($SessionId)
            Invoke-Http -method Get -path "sessions/$encodedSessionId/results/featureimportance"
        }
    }