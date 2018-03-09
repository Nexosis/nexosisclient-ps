Function Invoke-NexosisPredictTargetFromCsv {
    <# 
     .Synopsis
      Predicts target values from a CSV file for a set of features using a model
    
     .Description
      Predicts target values from a CSV file for a set of features using a model
    
     .Parameter ModelId
      Name of the data source (view, dataset, etc) to forecast

     .Parameter FilePath
      The path on disk to a CSV File (CRLF line endings only). It also must contain a header of columns and one to many 
      rows of comma seperated values for performing small sets of  batch prediction (filesize limted to aprox 1MB)
     
      .Parameter CsvString
      A String containing a blob of CSV data, including a header row to perform a small amount of batch predictions on. (String body limited to aprox 1MB).

     .Example
     # This example will cause 3 predictions of house price to occur.
     PS> Invoke-NexosisPredictTargetFromCsv -modelId 17904d91-a42f-4ca9-836f-956a13530beb -filePath .\dataToPredict.csv

     .Example
      # This example will cause 3 predictions of house price to occur.
      PS> $data = @(
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
    
      PS> $csvString = $data | ForEach-Object { 
            New-Object PSObject -Property $_ 
          ) | ConvertTo-CSv -NoTypeInformation
    
      PS> Invoke-NexosisPredictTargetFromCsv -modelId 17904d91-a42f-4ca9-836f-956a13530beb -csvString $csvString 
    #>[CmdletBinding(SupportsShouldProcess=$true)]
        Param(
            [Parameter(Mandatory=$true)]
            [Guid]$modelId,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            $FilePath,
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            $CsvString
        )
        process {
            if ($null -eq $modelId) { 
                throw "Argument '-modelId' cannot be null."
            }
    
            if (($null -eq $FilePath) -and (($null -eq $CsvString) -or ($CsvString.Trim().Length -eq 0))) {
                throw "You must provide only one of the following parameters '-FilePath' or '-CsvString', not both at once."
            }

            if ($CsvString.Trim().Length -gt 0) {
                if ($pscmdlet.ShouldProcess($modelId)) {
                    Invoke-Http -method Post -path "models/$modelId/predict" -Body $CsvString  -contentType "text/csv"
                }
            } elseif (($null -ne $FilePath) -and ($FilePath.Trim().Length -gt 0)) {
                if (Test-Path $FilePath) {
                    if ($pscmdlet.ShouldProcess($modelId)) {
                        Invoke-Http -method Post -path "models/$modelId/predict" -FileName $FilePath -contentType "text/csv"
                    }
                } else {
                    throw "File $FilePath doesn't exist."
                }
            } else {
                throw "CSV File cannot be null or empty."
            }
        }
    }