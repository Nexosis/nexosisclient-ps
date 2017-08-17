Function Get-AccountBalance {
<# 
 .Synopsis
 
 .Description
 
 .Example
 
 .Example
 
#>[CmdletBinding()]
	Param()
    process {
        $response = Invoke-Http -method Get -path "data" -needHeaders
        $hasResponseCode = [bool]($response.PSobject.Properties.name -match "StatusCode")
        
        if (($hasResponseCode -eq $true) -and ($response.StatusCode -eq 200)) {
            $response.Headers['Nexosis-Account-Balance']
        } else {
            return $response
        }
    }
}