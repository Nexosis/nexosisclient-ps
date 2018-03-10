Function Get-NexosisAccountQuota {
<# 
 .Synopsis
  Retrieves the Account Usage Status of your Nexosis API Account.

 .Description
  Given the current API Key, Get-NexosisAccountQuota returns the Account Usage Stats tracked for current pricing tier.

 .Link
 http://docs.nexosis.com/clients/powershell

 .Example
  # Retrieve current account balance
  Get-NexosisAccountQuota
#>[CmdletBinding()]
	Param()
    process {
        #  get as little data as possible since we just want the account quotas HTTP header.
        $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        $params['page'] = 0
        $params['pageSize'] = 1

        $response = Invoke-Http -method Get -path "data" -params $params -needHeaders

        $script:headers = @{}        

        if ($null -ne $response.Headers) {
            foreach ($key in $response.Headers.Keys) {
                if ($key.StartsWith("Nexosis-Account-")) {
                    $headers.Add($key.Replace('Nexosis-Account-','').Replace('-', ' '), $response.Headers[$key])
                }
            }
            # remove legacy header
            if ($script:headers.containskey("Balance")) {
                $script:headers.Remove("Balance")
            }
            $script:headers
        } else {
            $nexosisException = [NexosisClientException]::new("Error requesting account balance. Error trying to retrieve appropriate Account Balance Headers in HTTP Response. See ErrorResponse for more details.", $response.StatusCode)
            $nexosisException.ErrorResponse = $response
			throw $nexosisException
        }
    }
}