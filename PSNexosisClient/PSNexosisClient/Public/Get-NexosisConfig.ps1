Function Get-NexosisConfig {
<# 
 .Synopsis
  Retrieves a current configuration of the Nexosis Client.

 .Description
 This object stores defaults and variables used to configure the Nexosis Client for powershell. It
 has three properties: DefaultPageSize, ApiKey, and ApiBaseUrl. Changed to the returned object will
 not modify the underlying values, you must use Set-NexosisConfig to accomplish that. 

 .Link
 http://docs.nexosis.com/clients/powershell

 .Example
  Get-NexosisConfig
  DefaultPageSize ApiKey                           ApiBaseUrl                       
  --------------- ------                           ----------                       
  100             ******************************** https://api.uat.nexosisdev.com/v1
#>Param()
    process {
        $clone = New-Object PsObject
        $script:PSNexosisVars.psobject.properties | ForEach-Object {
            $clone | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
        }
        # return a clone so the config values cannot be modified, except through the Set-NexosisConfig command.
        $clone 
    }
}