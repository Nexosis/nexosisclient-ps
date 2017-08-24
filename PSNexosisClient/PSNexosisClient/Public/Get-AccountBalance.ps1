Function Get-AccountBalance {
<# 
 .Synopsis
  Retrieves the current balance of your Nexosis API Account in US Dollars.

 .Description
  Given the current API Key, Get-AccountBalance returns the current balance of the Nexosis API Account in US Dollars.

 .Link
 http://docs.nexosis.com/clients/powershell

 .Example
  # Retrieve current account balance
  Get-AccountBalance
#>[CmdletBinding()]
	Param()
    process {
        $response = Invoke-Http -method Get -path "data" -needHeaders
        $hasResponseCode = [bool]($response.PSobject.Properties.name -match "StatusCode")
        
        if (($hasResponseCode -eq $true) -and ($response.StatusCode -eq 200)) {
            $response.Headers['Nexosis-Account-Balance']
        } else {
           $response
        }
    }
}