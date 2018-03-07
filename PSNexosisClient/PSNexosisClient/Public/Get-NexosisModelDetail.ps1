Function Get-NexosisModelDetail {
    <# 
     .Synopsis
      Gets detailed information for a particular model.
    
     .Description
      Returns detailed information for a model.
     
     .Parameter ModelId
      Format - uuid. Model identifier for the model to retrieve
     
      .Link
      http://docs.nexosis.com/clients/powershell
    
     .Example
      # Gets detailed information for a particular model by Model ID
      Get-NexosisModelDetail -ModelId f1a27b5a-ef60-43f8-8998-fa48d0d14d09
    #>[CmdletBinding()]
	Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$True)]
        [GUID]$ModelId
	)
    process {
        $encodedModelId = [uri]::EscapeDataString($ModelId)
        Invoke-Http -method Get -path "models/$encodedModelId"
    }
}