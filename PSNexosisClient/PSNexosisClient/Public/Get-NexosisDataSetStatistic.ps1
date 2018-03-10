Function Get-NexosisDataSetStatistic {
<# 
 .Synopsis
  Gets the column stats for the given data source.

 .Description
  Returns statistics on each column in a dataset such as row count, min, max, mean, median, stddev, variance, count of non numeric values, and errors.
 
 .Parameter dataSetName
  The name of the data set for which to retrieve column stats.

 .Parameter columnName
  The column of the data set for which to retrieve stats.

 .Parameter dataType
  Interpret the column as the specified data type. Valid dataTypes are: 'string', 'text', 'numeric', or 'numericMeasure' 

 .Example
  # Return the Statistics from the DataSet named salesdata
  Get-NexosisDataSetStatistic -DataSetName salesdata
#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [string]$dataSetName,
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        [string]$columnName,
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        $dataType
	)
    process {
        $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        if ($null -ne $dataType) {
            $params['dataType'] = $dataType
        }

        $encodedDataSetName = [uri]::EscapeDataString($dataSetName)
        
        $result = Invoke-Http -method Get -path "data/$encodedDataSetName/stats/$columnName" -params $params
        if (($null -ne $columnName) -and ($columnName.Trim().Length -ne 0)) {
            $result.columns."$columnName"
        } else {
            $result.columns
        }
    }
}