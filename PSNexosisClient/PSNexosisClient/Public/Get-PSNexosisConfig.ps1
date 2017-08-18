Function Get-PSNexosisConfig {
<# 
 .Synopsis
  Retrieves the current configuration of the Nexosis Client.

 .Description
 This object stores defaults and variables used to configure the Nexosis Client for powershell. It
 has three properties: DefaultPageSize, ApiKey, and ApiBaseUrl. By changing these values, you can 
 change the API Enpoint address, API Key (initially set via ENV variable) and Default Page size for returning results.

 .Link
 http://docs.nexosis.com/clients/powershell

 .Example
  # Retrieve current Nexosis Client Configuration for powershell
  Get-PSNexosisConfig

  .Example
  # Change the default number of records returned from 100 to 1000
  (Get-NexosisConfig).DefaultPageSize=1000
#>
    $script:PSNexosisVars
}