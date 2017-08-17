Function Get-ImportDetail {
<# 
 .Synopsis
  Retrieve information about request to import data into Axon

 .Description
  Retrieve information about request to import data into Axon
 
 .Parameter importId
  The GUID of the Import

  .Example
   # Get import details in
   Get-ImportDetail 015d7a16-8b2b-4c9c-865d-9a400e01a291
#>[CmdletBinding()]
	Param(
      [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
		  [Guid]$importId
    )
    process {
      Invoke-Http -method Get -path "imports/$importId"
    }
}