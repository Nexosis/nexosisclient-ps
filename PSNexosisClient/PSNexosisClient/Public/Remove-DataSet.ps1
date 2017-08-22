Add-Type -TypeDefinition @"
	[System.FlagsAttribute]
    public enum DataSetDeleteOptions
    {
        None = 0,
        CascadeSessions = 1
    }
"@

Function Remove-DataSet {
<# 
 .Synopsis
 Remove an entire dataset or a subset of data in the dataset. 

 .Description
  If a date range is specified, then only data in that date range is removed from the dataset. Otherwise,
  all data is removed from the dataset.  If the cascade option is specified and will also include the removal 
  of associated sessions.

 .Parameter DataSetName
  Name of the dataset from which to remove data.

 .Parameter StartDate  
  Limits data removed to those on or after the specified date,  formatted as a date-time in ISO8601.

 .Parameter EndDate 
  Limits data removed to those on or before the specified date, formatted as a date-time in ISO8601.

 .Parameter CascadeOption
  Options for cascading the delete.
  When None, only deletes the dataset, or a range of data in the dataset. 
  When CascadeSessions, deletes datasets and if start and/or end date are supplied,
  sessions created in that date range are also deleted.

 .Example
  # Remove the dataset named 'salesdata'
  Remove-DataSet -dataSetName 'salesdata'

 .Example
  # Remove the dataset named 'salesdata' and delete all associated sessions
  Remove-DataSet -dataSetName 'salesdata' -cascadeOption CascadeSession

 .Example
  # Remove data within the dataset between start and end date, and force (no prompt)
  Remove-DataSet -dataSetName 'salesdata' -startDate '2017-02-25T00:00:00+00:00' -endDate '2017-03-25T00:00:00+00:00' -force

  .Example
  # Get all datasets that match the partial name 'PSTest' and deletes them.
  (Get-DataSet -partialName 'PSTest') | foreach { $_.DataSetName } | Remove-DataSet
#>[CmdletBinding(SupportsShouldProcess=$true)] 
	Param(
		[Parameter(ValueFromPipeline=$True, Mandatory=$true)]
		[string]$dataSetName,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		[DateTime]$startDate,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		[DateTime]$endDate,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
		[DataSetDeleteOptions]$cascadeOption,
		[switch] $Force=$False
	)
	process {
		$params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
		
		if (($dataSetName -eq $null ) -or ($dataSetName.Trim().Length -eq 0)) { 
			throw "Argument '-DataSetName' cannot be null or empty."
		}

		if ($startDate -ne $null) { 
			$params['startDate'] = "$startDate"
		}
		
		if ($endDate -ne $null) {
			$params['endDate'] = "$endDate"
		}

		if ($cascadeOption -band [DataSetDeleteOptions]::CascadeSessions) { 
			$params.Add('cascade','session')
		}

		if ($pscmdlet.ShouldProcess($dataSetName)) {
			if ($Force -or $pscmdlet.ShouldContinue("Are you sure you want to permanently delete dataset '$dataSetName'.", "Confirm Delete?")) {
				Invoke-Http -method Delete -path "data/$dataSetName" -params $params
			}
		}
	}
}
