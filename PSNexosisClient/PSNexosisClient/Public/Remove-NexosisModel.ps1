Function Remove-NexosisModel {
<# 
.Synopsis
Removes a single Model from your account 

.Description
Removes a single Model from your account

.Parameter ModelId
The GUID of the model to delete.

.Parameter DataSourceName
Limits models to be removed to those for a particular data source.

.Parameter CreatedBeforeDate
Limits models to be removed to those created on or before the specified date. Format as date-time (as date-time in ISO8601).

.Parameter CreatedAfterDate
Limits models to be removed to those created on or after the specified date. Format as date-time (as date-time in ISO8601).


.Example
# Remove the Model by model ID

#>[CmdletBinding(SupportsShouldProcess=$true)] 
  Param(
    [Parameter(ValueFromPipeline=$True, Mandatory=$false)]
    [Guid]$modelId,
    [Parameter(ValueFromPipeline=$True, Mandatory=$false)]
		[string]$DataSourceName,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$false)]
		[DateTime]$CreatedAfterDate,
		[Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$false)]
		[DateTime]$CreatedBeforeDate, 
    [switch] $Force=$False
  )
    process {
      $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

      # Session ID will not be used with other parameters
      if ($modelId -eq $null) {
          if ($DataSourceName -ne $null) {
              $params['dataSourceName'] = $DataSourceName
          }

          if ($CreatedAfterDate -ne $null) { 
              $params['createdAfterDate'] = $CreatedAfterDate
          }

          if ($CreatedBeforeDate -ne $null) {
              $params['createdBeforeDate'] = $CreatedBeforeDate
          }

          if ($pscmdlet.ShouldProcess($dataSetName)) {
              if ($Force -or $pscmdlet.ShouldContinue("Are you sure you want to permanently delete the model(s) for datasource '$dataSourceName'.", "Confirm Delete?")) {
                  Invoke-Http -method Delete -path "models" -params $params
              }
          }
      } else {
        if (
          $DataSourceName.Length -gt 0 -or
          $createdAfterDate -ne $null -or
          $createdBeforeDate -ne $null
        ) {
            throw "Parameter '-ModelId' is exclusive and cannot be used with any other parameters."
        }
        
        if ($pscmdlet.ShouldProcess($dataSetName)) {
          if ($Force -or $pscmdlet.ShouldContinue("Are you sure you want to permanently delete mode '$modelId'.", "Confirm Delete?")) {
              Invoke-Http -method Delete -path "models/$modelId" -params $params
          }
        }
    }
  }
}
