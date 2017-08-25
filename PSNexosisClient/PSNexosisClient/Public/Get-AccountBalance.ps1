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
        #  get as little data as possible since we just want the account balance HTTP header.
        $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        $params['page']=0
        $params['pageSize'] = 1

        $response = Invoke-Http -method Get -path "data" -params $params -needHeaders
        
        if (($null -ne $response.Headers) -and ($response.Headers.ContainsKey('Nexosis-Account-Balance'))) {
            $response.Headers['Nexosis-Account-Balance'] 
        } else {
            $nexosisException = [NexosisClientException]::new("Error requesting account balance. No Nexosis-Account-Balance header in HTTP Response. See ErrorResponse for more details.", $response.StatusCode)
            $nexosisException.ErrorResponse = $response
			throw $nexosisException
        }
    }
}