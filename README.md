# PSNexosisClient

Nexosis API Client for PowerShell

This software is provided as a way to include Nexosis API functionality from your PowerShell command line.

You can read about the Nexosis API at https://developers.nexosis.com

Pull requests are welcome

[![Build status](https://ci.appveyor.com/api/projects/status/h739j05wvgg1g7o1?svg=true)](https://ci.appveyor.com/project/Nexosis/nexosisclient-ps)

## Examples of library usage

List of all commands

```powershell
PS C:\> ((Get-Module PSNexosisClient).ExportedCommands).Keys

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

To get basic help on commands in the PSNexosisClient, type:

```powershell
PS C:\> get-help Get-DataSet
```

and that will return

```
NAME
    Get-DataSet
    
SYNOPSIS
    Gets the list of all datasets that have been saved to the system.
    
    
SYNTAX
    Get-DataSet [[-partialName] <String>] [[-page] <Int32>] [[-pageSize] <Int32>] [<CommonParameters>]
    
    
DESCRIPTION
    Returns a list of all the stored datasets and related data.
    

RELATED LINKS
    http://docs.nexosis.com/clients/powershell

REMARKS
    To see the examples, type: "get-help Get-DataSet -examples".
    For more information, type: "get-help Get-DataSet -detailed".
    For technical information, type: "get-help Get-DataSet -full".
    For online help, type: "get-help Get-DataSet -online"
```

To just get examples, run:
```powershell
PS C:\> get-help Get-DataSet -Examples
```

which will return all the examples only:
```powershell
NAME
    Get-DataSet
    
SYNOPSIS
    Gets the list of all datasets that have been saved to the system.
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\> Get-DataSet -partialName 'sales'

    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\> Get-DataSet -page 0 -pageSize 2 | ConvertTo-Json -Depth 4
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:\> Get-DataSet -partialName 'sales' -page 0 -pageSize 20
```

To get the full details of Help documents on a particular Module in the PSNexosisClient module, type:

```powershell 
PS C:\> help New-DataSet
```

Help Documentation contains more detailed explanation:
```powershell 
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
    
If the dataset already exists, adds rows to the dataset. If the specified data contains records with timestamps that already exist in the dataset, those records will be overwritten.
    

RELATED LINKS

REMARKS
    To see the examples, type: "get-help New-DataSet -examples".
    For more information, type: "get-help New-DataSet -detailed".
    For technical information, type: "get-help New-DataSet -full".
```

## Some Examples
Get all datasets
```powershell
PS C:\> Get-Dataset -partialName 'salesdata'
```

Commands can be chained together. The following example will retrieve all datasets whose data set name matches 'Location' - and will return the status of all the S3 imports:

```powershell
 PS C:\> ((Get-DataSet -partialName 'Location') | Foreach { $_.DataSetName } | Get-Import) | Where type -eq 's3' | Format-Table -Property @('datasetname', 'requestedDate', 'status')
```

Here's example output:

```
dataSetName requestedDate                    status   
----------- -------------                    ------   
Location-A  2017-07-25T14:11:24.072413+00:00 completed
Location-A  2017-07-31T19:55:54.77986+00:00  completed
Location-A  2017-07-31T20:48:59.757254+00:00 completed
Location-A  2017-07-31T20:49:49.834596+00:00 completed
Location-A  2017-07-31T21:13:01.534355+00:00 completed
Location-A  2017-07-31T21:29:10.492391+00:00 completed
Location-A  2017-07-31T21:30:46.964879+00:00 completed
Location-A  2017-07-31T21:31:58.940308+00:00 completed
Location-A  2017-07-31T21:33:01.357326+00:00 completed
Location-A  2017-07-31T21:39:43.500755+00:00 completed
Location-A  2017-07-31T21:48:28.43288+00:00  completed
Location-A  2017-07-31T21:50:08.738356+00:00 completed
Location-A  2017-07-31T21:59:29.412464+00:00 completed
Location-A  2017-07-31T22:00:02.808693+00:00 completed
Location-A  2017-07-31T22:17:33.119814+00:00 completed
Location-A  2017-07-31T22:19:04.318954+00:00 completed
Location-A  2017-07-31T22:22:06.416325+00:00 completed
```