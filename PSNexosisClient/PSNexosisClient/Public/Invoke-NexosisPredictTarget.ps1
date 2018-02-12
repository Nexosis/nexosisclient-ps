Function Invoke-NexosisPredictTarget {
    <# 
     .Synopsis
      Predicts target values for a set of features using a model
    
     .Description
      Predicts target values for a set of features using a model
    
     .Parameter ModelId
      Name of the data source (view, dataset, etc) to forecast

     .Parameter Data
     An array of hashtables 
     .Example
     # This example will cause 3 predictions of house price to occur.
      $data = @(
                @{
                    LotFrontage= "65"
                    LotArea = "8450"
                    YearBuilt="2003"
                }
                @{
                    LotFrontage = "80"
                    LotArea = "96000"
                    YearBuilt = "1976"
                }
                @{
                    LotFrontage = "68"
                    LotArea = "11250"
                    YearBuilt = "2001"
                }
            )  
        
        PS> Invoke-NexosisPredictTarget -modelId 17904d91-a42f-4ca9-836f-956a13530beb -data $data
    #>[CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(Mandatory=$true)]
        [Guid]$modelId,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        $data
    )
    process {
        if (($null -eq $data) -or ($data -isnot [Array]) -or ($data.Count -lt 1))
        {
            throw "Parameter '-data' must be an array containing a hashtable of features needed to make the prediction."
        }

        $requestData = @{ data = $data.SyncRoot }
        if ($pscmdlet.ShouldProcess($modelId)) {       
            Invoke-Http -method Post -path "models/$modelId/predict" -Body ($requestData | ConvertTo-Json -depth 6)
        }
    }
}