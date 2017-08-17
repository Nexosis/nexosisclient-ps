#Requires -Version 3.0
#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\PSNexosisClient.psd1).Version

Foreach($import in @($Public + $Private))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Add-Type -AssemblyName System.Web

# Setup Constant Variables
Set-Variable -Name UserAgent -Option Constant -Visibility Private -Scope Script -Value "Nexosis-PS-API-Client/$moduleVersion"
Set-Variable -Name MaxPageSize -Option Constant -Visibility Public -Scope Script -Value 1000
Set-Variable -Name ApiBaseUrl -Option Constant -Visibility Public -Scope Script -Value 'https://ml.nexosis.com/v1'

if ($null -eq $Env:NEXOSIS_BASE_TEST_URL) {
    $BaseUrl = $script:ApiBaseUrl
 } else {
    $BaseUrl = ($Env:NEXOSIS_BASE_TEST_URL)
 }

Write-Verbose $script:UserAgent

Enum ResultInterval
{
    Hour
    Day
    Week
    Month
    Year
}

# Setup a hashtable of configurable variables
$script:PSNexosisVars = new-object PSObject -Property @{
	ApiKey  = $Env:NEXOSIS_API_KEY
	ApiBaseUrl = $BaseUrl
    DefaultPageSize=100
}

# Export all public functions
Export-ModuleMember -Function $Public.Basename