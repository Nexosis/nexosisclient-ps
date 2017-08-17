$Verbose = @{}
# For build automation to enable verbose
if($ENV:NCBranchName -notlike "master" -or $env:NCCommitMessage -match "!verbose")
{
	$Verbose.add("Verbose",$True)
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