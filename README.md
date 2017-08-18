# PSNexosisClient

Nexosis API Client for PowerShell

[![Build status](https://ci.appveyor.com/api/projects/status/h739j05wvgg1g7o1?svg=true)](https://ci.appveyor.com/project/Nexosis/nexosisclient-ps)

## Examples of library usage

List of all commands

```powershell
PS > ((Get-Module PSNexosisClient).ExportedCommands).Keys

Key
---
Get-AccountBalance
Get-DataSet
Get-DataSetData
Get-Import
Get-ImportDetail
Get-PSNexosisConfig
Get-Session
Get-SessionResult
Get-SessionStatus
Get-SessionStatusDetail
Import-DataSetFromCsv
Import-DataSetFromS3
New-DataSet
Remove-DataSet
Remove-Session
Start-ForecastSession
Start-ImpactSession
```

To get Help on a particular Module, type:

```powershell 
PS > help New-DataSet


NAME
    New-DataSet
    
SYNOPSIS
    This operation creates a new dataset or updates an existing dataset using data from a PSCustomObject.
    
    
SYNTAX
    New-DataSet [-dataSetName] <String> [-data] <Object> [[-columnMetaData] <Object>] [-WhatIf] [-Confirm] [<CommonParameters>]
    
    
DESCRIPTION
    This operation creates a new dataset using data provided in an object formatted as an Array of HashTables, like so:
    
    $data = @(
    	@{
    		timestamp = "2013-01-01T00:00:00+00:00"
    		sales = "1500.56"
    		transactions = "195.0"
    	},
    	@{
    		timestamp = "2013-01-02T00:00:00+00:00"
    		sales = "4078.52"
    		transactions = "696.0"
    	},
    	@{
    		timestamp = "2013-01-03T00:00:00+00:00"
    		sales = "4545.69"
    		transactions = "743.0"
    	},
    	@{
    		timestamp = "2013-01-04T00:00:00+00:00"
    		sales = "4872.63"
    		transactions = "797.0"
    	},
    	@{
    		timestamp = "2013-01-05T00:00:00+00:00"
    		sales = "2420.81"
    		transactions = "367.0"
    	}
    ) 
    
    Optionally, metadata for the columns can be submitted to help describe the data being uploaded as a hashtable, for example:
    
    $columns = @{
    	timestamp = @{
    		dataType = "date"
    		role = "timestamp"
    		imputation = "zeroes"
    		aggregation = "sum"
    	}
    	sales = @{
    		dataType = "numeric"
    		role = "target"
    		imputation = $null
    		aggregation = $null
    	}
    	transactions = @{
    		dataType = "numeric"
    		role = "none"
    		imputation = "zeroes"
    		aggregation = "sum"
    	}
    }
    
    If the dataset already exists, adds rows to the dataset. If the specified data contains records with timestamps that
    already exist in the dataset, those records will be overwritten.
    

RELATED LINKS

REMARKS
    To see the examples, type: "get-help New-DataSet -examples".
    For more information, type: "get-help New-DataSet -detailed".
    For technical information, type: "get-help New-DataSet -full".
```

## Some Examples
Get all datasets
```powershell
Get-Dataset -partialName 'PSTest'
```

Get all the datasets that match the partial name 'Location' and list all the S3 Imports.
```powershell
((Get-DataSet -partialName 'Location') | Foreach { $_.DataSetName } | Get-Import) | Where type -eq 's3' | Format-Table -Property @('status', 'datasetname', 'requestedDate')
```

Ref: https://blogs.technet.microsoft.com/pstips/2014/06/17/powershell-scripting-best-practices/
Ref: https://xainey.github.io/2017/powershell-module-pipeline/