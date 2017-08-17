# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "Get-PSNexosisConfig" {
	Context "unit tests" {
        Set-StrictMode -Version latest		

        It "has config variables" {
            $var = Get-PSNexosisConfig 
            $var.ApiKey | should match "^[a-f0-9]{32}$"
            $var.ApiBaseUrl | should match "^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$"
            $var.DefaultPageSize | should BeGreaterThan 0
            $var.DefaultPageSize | should BeLessThan 1001
        }
    }
}