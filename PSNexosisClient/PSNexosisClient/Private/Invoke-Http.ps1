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
	$headers = @{}
	$headers.Add("accept", $acceptHeader)
	$headers.Add("api-key", $script:PSNexosisVars.ApiKey)
	$headers.Add("User-Agent", $script:UserAgent)

	$endpoint = "$($script:PSNexosisVars.ApiBaseUrl)/$path"
	$Request = [System.UriBuilder]$endpoint
	$Request.Query = $params.ToString()
    $uri = [string]$Request.Uri.AbsoluteUri

	Try {
		if ($fileName -ne $null) {
			# submit request with file
			Write-Verbose "Invoke-WebRequest -Uri $uri -Method $method -Headers $($headers.GetEnumerator()  | % { "$($_.Name)=$($_.Value)" }) -ContentType $contentType -InFile $fileName"
			$httpResults = Invoke-WebRequest -Uri $uri -Method $method -Headers $headers -ContentType $contentType -InFile $fileName
		} elseif ($body -ne $null) {
			# filename null, body is populated, submit body data
			Write-Verbose "Invoke-WebRequest -Uri $uri -Method $method -Headers $($headers.GetEnumerator()  | % { "$($_.Name)=$($_.Value)" }) -Body $body -ContentType $contentType"
			$httpResults = Invoke-WebRequest -Uri $uri -Method $method -Headers $headers -Body $body -ContentType $contentType
		} else {		
			# no file, no body
			Write-Verbose "Invoke-WebRequest -Uri $uri -Method $method -Headers $($headers.GetEnumerator()  | % { "$($_.Name)=$($_.Value)" }) -ContentType $contentType"
			$httpResults = Invoke-WebRequest -Uri $uri -Method $method -Headers $headers -ContentType $contentType			 
		}

		if ($httpResults.StatusCode -ge 200 -and $httpResults.StatusCode -le 299)  {
			 
			if ($method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Head) {
				# If a HTTP Head, .Content is useless,
				# return the results so calls can work with headers, etc.
				$httpResults
			} elseif ($needHeaders -eq $true) {
				# Need headers (Get-AccountBalance, etc)
				# return results
				$httpResults
			} elseif ($acceptHeader -eq 'application/json') {
				# Return object from JSON
				$httpResults.Content | ConvertFrom-Json
			} elseif ($acceptHeader -eq 'text/csv') {
				# Return raw csv
				$httpResults.Content
			} else {
                # Just return unformatted HTTP body / content
				$httpResults.Content
			}
		} else {
            # if it's not 200-299 status code and not an exception (400-599), just return the WebRequest object
            $httpResults
        }
	} Catch {
		# TODO - return a NexosisClientException Object 
		if ($_.Exception.Response -ne $null) {
			Write-Verbose  "StatusCode: $($_.Exception.Response.StatusCode.value__)"
			Write-Verbose  "StatusDescription: $($_.Exception.Response.StatusDescription)" 
			
            if ($_.Exception.Response.Method -ne 'HEAD') {
                $result = $_.Exception.Response.GetResponseStream()
			    $reader = New-Object System.IO.StreamReader($result)
			    $reader.BaseStream.Position = 0
				$reader.DiscardBufferedData()
				# Capture JSON Error message from respose stream
				$responseJsonError = ($reader.ReadToEnd() | ConvertFrom-Json)
				
				$nexosisException = [NexosisClientException]::new($responseJsonError.message, [PSObject]$responseJsonError)
				throw $nexosisException 
            } else {
				$nexosisException = [NexosisClientException]::new($_.Exception.Response.StatusDescription, [int]$_.Exception.Response.StatusCode)
				throw $nexosisException
            }
		} else {
			$nexosisException = [NexosisClientException]::new($_.Exception.message, $_.Exception)
			throw $nexosisException
		}
	}
}
