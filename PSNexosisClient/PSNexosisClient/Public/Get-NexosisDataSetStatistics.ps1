Function Get-NexosisDataSetStatistics {
<# 
 .Synopsis
  Gets the column stats for the given data source.

 .Description
  Returns statistics on each column in a dataset such as row count, min, max, mean, median, stddev, variance, count of non numeric values, and errors.
 
 .Parameter dataSetName
  The name of the data set for which to retrieve column stats.

 .Example
  # Return the Statistics from the DataSet named salesdata
  Get-NexosisDataSetStatistics -DataSetName salesdata
#>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [string]$dataSetName
	)
    process {
        $encodedDataSetName = [uri]::EscapeDataString($dataSetName)
        $result = Invoke-Http -method Get -path "data/$encodedDataSetName/stats"
        $statistics = @()
        foreach ($column in $result.columns) {
            $entry = @{}
            $entry.Add(($column | Get-Member)[-1].Name, $column.(($column | Get-Member)[-1].Name))
            $statistics += $entry
        }
        $statistics
    }
}