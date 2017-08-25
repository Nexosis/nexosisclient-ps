Function New-View {
    <# 
     .Synopsis
      This operation creates or updates a view definition.
    
     .Description
      This operation creates or updates a view definition.
    
     .Parameter ViewName
      Name of the view definition to create or update
    
     .Parameter DataSetName
     Name of the dataset to add data.

     .Parameter Joins
     A data structure containing the Join Definition for how to join another DataSet with the dataset specified in Joins.

        @(
            @{
                name="rightDataSetName"
                columnOptions= @{
                    columnNameToIncludeInJoin=@{
                        alias="columnAlias"
                    }
                }
            }
        )

     .Parameter columnMetadata
     An optional data structure containing metadata describing the columns for a view. By default, a view will inherit 
     the metadata from the source DataSets that construct it. If the Columns Metadata is set on a view directly, it
     will overriding the source datasets columns metadata on the view alone.
    
  .Link
     http://docs.nexosis.com/clients/powershell

  .Link
     http://docs.nexosis.com/guides/views

     .Example
     # The Following is an example join definition that joins dataset 'SalesData' with dataset 'promoData' on the
     # 'timestamp' column. All columns from both datasets will be joined together. ColumnOptions are optional and
     # are only used to renamed (alias) a column or to specify what time interval to join on for a timestamp data 
     # type. 

    $joins = @(
                @{
                    dataSetName="promoData"
                    columnOptions = @{
                        timestamp=@{
                            joinInterval="Day"
                            alias="promoDate"
                        }
                        isPromo=@{
                            alias="promo"
                        }
                    }
                }
            )

    New-View -viewName 'SalesWithPromosView' -dataSetName "salesData" -joins $joins 
    
    #>[CmdletBinding(SupportsShouldProcess=$true)]
        Param(
            [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
            [string]$viewName,
            [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
            [string]$dataSetName,
            [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
            $joins=@(),
            [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
            $columnMetaData
        )
        process {
            if ($viewName.Trim().Length -eq 0) { 
                throw "Argument '-viewName' cannot be null or empty."
            }
    
            if ($joins -isnot [System.Array]) {
                throw "Parameter '-joins' must be an array of hashes."
            }
            
            if ($joins.Length -lt 1) {
                throw "Parameter '-joins' must contain at least one join."
            }
    
            if ($null -ne $columnMetaData -and $columnMetaData -isnot [Hashtable])
            {
                throw "Parameter '-columnMetaData' must be a hashtable of column metadata for the data."	
            }
    
            if ($null -eq $columnMetaData) {
                $viewDefinition = @{
                    dataSetName = $dataSetName
                    joins = @()
                }
            } else {
                $viewDefinition = @{
                    dataSetName = $dataSetName
                    columns = $columnMetaData
                    joins = @()
                }
            }

            foreach ($join in $joins) {
                $joinToAdd = @{
                    dataSet=@{
                        name = $join["dataSetName"]
                    }
                    columnOptions=$join["columnOptions"]
                    joins=$null
                }
               
                $viewDefinition["joins"] += $joinToAdd
            }

            if ($dataSetName.Trim().Length -eq 0) { 
                throw "Argument '-DataSetName' cannot be null or empty."
            }
    
            if ($pscmdlet.ShouldProcess($viewName)) {
                Invoke-Http -method Put -path "views/$viewName" -Body ($viewDefinition | ConvertTo-Json -depth 6)
            }
        }
    }