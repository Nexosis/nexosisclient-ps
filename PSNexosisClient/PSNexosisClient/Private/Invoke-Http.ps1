function Invoke-Http {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true)]
		[string]$Path,
		[Parameter(Mandatory=$true)]
		[Microsoft.PowerShell.Commands.WebRequestMethod]$method,
		[Parameter(Mandatory=$false)]
		$params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty),
		[Parameter(Mandatory=$false)]
		$contentType='application/json',
		[Parameter(Mandatory=$false)]
		$body,
		[Parameter(Mandatory=$false)]
		$fileName,
		[Parameter(Mandatory=$false)]
		$acceptHeader='application/json',
		[Parameter(Mandatory=$false)]
		[switch]$needHeaders=$false
	)
    if ($null -eq $script:PSNexosisVars.ApiKey) {
        Set-NexosisConfig -SetApiKeyFromEnvironment
    } 

	$headers = @{}
	$headers.Add("accept", $acceptHeader)
	$headers.Add("api-key", "********************************")
	$headers.Add("User-Agent", $script:UserAgent)

	$endpoint = "$($script:PSNexosisVars.ApiBaseUrl)/$path"
	$Request = [System.UriBuilder]$endpoint
	$Request.Query = $params.ToString()
    $uri = [string]$Request.Uri.AbsoluteUri

	Try {
		if ($fileName -ne $null) {
			# submit request with file
			Write-Verbose "Invoke-WebRequest -Uri $uri -Method $method -Headers $($headers.GetEnumerator()  | % { "$($_.Name)=$($_.Value)" }) -ContentType $contentType -InFile $fileName"
			# replace acceptHeader with actual key so we don't print in in VerboseMode
			$headers["api-key"] = $script:PSNexosisVars.ApiKey
			$httpResults = Invoke-WebRequest -Uri $uri -Method $method -Headers $headers -ContentType $contentType -InFile $fileName
		} elseif ($body -ne $null) {
			# filename null, body is populated, submit body data
			Write-Verbose "Invoke-WebRequest -Uri $uri -Method $method -Headers $($headers.GetEnumerator()  | % { "$($_.Name)=$($_.Value)" }) -Body $body -ContentType $contentType"
			# replace acceptHeader with actual key so we don't print it in VerboseMode
			$headers["api-key"] = $script:PSNexosisVars.ApiKey
			$httpResults = Invoke-WebRequest -Uri $uri -Method $method -Headers $headers -Body $body -ContentType $contentType
		} else {		
			# no file, no body
			Write-Verbose "Invoke-WebRequest -Uri $uri -Method $method -Headers $($headers.GetEnumerator()  | % { "$($_.Name)=$($_.Value)" }) -ContentType $contentType"
			# replace acceptHeader with actual key so we don't print in in VerboseMode
			$headers["api-key"] = $script:PSNexosisVars.ApiKey
			$httpResults = Invoke-WebRequest -Uri $uri -Method $method -Headers $headers -ContentType $contentType			 
		}

		# Status code in 200's and not an exception
		if ($httpResults.StatusCode -ge 200 -and $httpResults.StatusCode -le 299)  {	 
			if (($method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Head) -or ($needHeaders -eq $true)) {
				# If HTTP Head Request, $httpResults.Content won't exist so
				# return the results so calls can work with headers, etc.
				# If need headers (Get-NexosisAccountBalance, etc), return entire HttpRequest object
				# Callers need to handle checking statuscode and handling Headers and Content
				$httpResults
			} elseif ($acceptHeader -eq 'application/json') {
				# Return HTTP Content from JSON
				$httpResults.Content | ConvertFrom-Json
			} else {
				# Return raw content if expecting CSV like when accept header is 'text/csv' 
                # or any other case, just return raw HTTP body / content
				$httpResults.Content
			}
		} else {
            # if it's not 200-299 status code and not an exception (400-599), just return the WebRequest object
            assert($true, "Unexpected condition - Invoke-WebRequest had a status code between 200-299 but did not throw an exception. Nexosis API should not throw 300's.")
        }
	} Catch {
		# Make sure there's a Response object, so we can read in server-side messages
		if ($_.Exception.Response -ne $null) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDescription = $_.Exception.Response.StatusDescription
			
			# If it's an HTTP HEAD request, there's no body to capture the error details from.
            if ($_.Exception.Response.Method -eq 'HEAD') {
				$nexosisException = [NexosisClientException]::new($_.Exception.Response.StatusDescription, [int]$_.Exception.Response.StatusCode)
				throw $nexosisException
            } else {
                try {
					# Read response stream for any error message.
					$result = $_.Exception.Response.GetResponseStream()
					$reader = New-Object System.IO.StreamReader($result)
					$reader.BaseStream.Position = 0 # reset the response stream
					$reader.DiscardBufferedData()
					$responseRawError = $reader.ReadToEnd()
					# Capture JSON Error message from respose stream
					$responseJsonError = $responseRawError | ConvertFrom-Json
					# create Nexosis Client Exception
                    $nexosisException = [NexosisClientException]::new($responseJsonError.message, [PSObject]$responseJsonError)
				} catch {
					# Content stream was probably not JSON, wrap status description and code to be thrown
                    $nexosisException = [NexosisClientException]::new($statusDescription, $statusCode)
				}
				throw $nexosisException 
            }
		} else {
			# Unexpected exception - wrap it in a NexosisClientException.
			$nexosisException = [NexosisClientException]::new($_.Exception.message, $_.Exception)
			throw $nexosisException
		}
	}
}
