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
Set-Variable -Name ServerDefaultPageSize -Option Constant -Visibility Public -Scope Script -Value 50
Set-Variable -Name ApiBaseUrl -Option Constant -Visibility Public -Scope Script -Value 'https://ml.nexosis.com/v1'

if ($null -eq $Env:NEXOSIS_API_TESTURI) {
    $BaseUrl = $script:ApiBaseUrl
 } else {
    $BaseUrl = ($Env:NEXOSIS_API_TESTURI)
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

Enum PredictionDomain
{
    Regression
    Classification
}

Enum ImportContentType
{
    json
    csv
}

# Setup a hashtable of configurable variables with Defaults
$script:PSNexosisVars = new-object PSObject -Property @{
	ApiKey = $Env:NEXOSIS_API_KEY
	ApiBaseUrl = $BaseUrl
    DefaultPageSize=100
}


Add-Type -TypeDefinition @"
using System;
using System.Management.Automation;
using System.Collections.Generic;
using System.Net;

public class NexosisClientException : Exception
{
    public NexosisClientException(string message, Exception inner) : base(message, inner) { }

    public NexosisClientException(string message, HttpStatusCode statusCode) : base(message)
    {
        StatusCode = statusCode;
        ErrorResponse = null;
    }

    public NexosisClientException(string message, PSObject response) : base(message)
    {
        StatusCode = (HttpStatusCode)response.Properties["StatusCode"].Value;
        ErrorResponse = response;
    }

    public HttpStatusCode StatusCode { get; set; }
    public PSObject ErrorResponse { get; set; }
}
"@

# Export all public functions
Export-ModuleMember -Function $Public.Basename