# PSNexosisClient

Nexosis API Client implemented in Powershell

[![Build status](https://ci.appveyor.com/api/projects/status/h739j05wvgg1g7o1?svg=true)](https://ci.appveyor.com/project/Nexosis/nexosisclient-ps)

## Examples of library usage

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