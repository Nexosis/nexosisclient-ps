Function Set-NexosisConfig {
    <# 
     .Synopsis
      Sets current configuration settings of the Nexosis Client.
    
     .Description
     This object stores defaults and variables used to configure the Nexosis Client for powershell. It
     has three properties: DefaultPageSize, ApiKey, and ApiBaseUrl. By changing these values, you can 
     change the API Enpoint address, API Key (initially set via ENV variable) and Default Page size for returning results.
    
     .Link
     http://docs.nexosis.com/clients/powershell
    
     .Example
     Set-NexosisConfig -ReadKeyFromHost

     .Example
      # Load the API Key from the Environment
      Set-NexosisConfig -SetApiKeyFromEnvironment
    
      .Example
      # Set the API key
      Set-NexosisConfig -ApiKey abcdefghijklmnopqrstuvwxyz123456
    
      .Example
      # Change the default number of records returned from 100 to 1000
      Set-NexosisConfig -DefaultPageSize 1000
    #>[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$True)]
        [string]$ApiKey,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$True)]
        [int]$DefaultPageSize=[int]::MinValue,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$True)]
        [string]$ApiBaseUrl,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$True)]
        [switch]$SetApiKeyFromEnvironment=$false
    )
    process {
        if (($setApiKeyFromEnvironment) -and ($ApiKey.Trim().Length -gt 0)) {
            throw "Parameters -ApiKey and -SetApiKeyFromEnvironment cannot be used together."
        }

        if ($setApiKeyFromEnvironment) {
            if ($null -eq $Env:NEXOSIS_API_KEY) {
                throw "The NEXOSIS_API_KEY environment variable has not been set. You can find your key by signing in with your account at https://developers.nexosis.com/developer"
            }
            if ($Env:NEXOSIS_API_KEY -match "^[a-f0-9]{32}$") {
                if ($pscmdlet.ShouldProcess($Env:NEXOSIS_API_KEY)) {
                    $script:PSNexosisVars.ApiKey = $Env:NEXOSIS_API_KEY
                } 
            } else {
                throw "Invalid format. Environment variabled NEXOSIS_API_KEY must be a string of 32 alphanumeric characters."
            }
        }

        if ($ApiKey.Trim().Length -gt 0) {
            if ($ApiKey -match "^[a-f0-9]{32}$") {
                if ($pscmdlet.ShouldProcess($ApiKey)) {
                    $script:PSNexosisVars.ApiKey = $ApiKey
                }
            } else {
                throw "Invalid format. Parameter -ApiKey must be a string of 32 alphanumeric characters."
            }
        }

        if ($ApiBaseUrl.Trim().Length -ne 0) {
            if ($ApiBaseUrl -match "https?:\/\/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)") {
                if ($pscmdlet.ShouldProcess($ApiBaseUrl)) {
                    $script:PSNexosisVars.ApiBaseUrl = $ApiBaseUrl
                }
            } else {
                throw "Parameter -BaseUrl must be formatted as a URL."
            }
        }

        if ($DefaultPageSize -ne [int]::MinValue) {
            if ($DefaultPageSize -lt 1 -or $DefaultPageSize -gt 1000) {
                throw "Parameter -DefaultPageSize must be an integer between 1 and 1000."
            }
            if ($pscmdlet.ShouldProcess($DefaultPageSize)) {
                $script:PSNexosisVars.DefaultPageSize = $DefaultPageSize
            }
        }
    }
}