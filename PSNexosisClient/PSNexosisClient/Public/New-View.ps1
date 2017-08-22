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

     .Parameter RightDataSetName
     Name of the dataset to join to
    
     .Parameter columnsMetaData
     A hashtable containing metadata that describes the columns for the view (overriding the source dataset columns metadata), such as data types and imputation and aggragation strategies.
    
     .Example

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
    
            $viewDefinition = @{
                dataSetName = $dataSetName
                columns = $columnMetaData
                joins = @()
            }

            foreach ($join in $joins) {
                $joinToAdd = @{
                    dataSet=@{
                        dataSetName = $join["dataSetName"]
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