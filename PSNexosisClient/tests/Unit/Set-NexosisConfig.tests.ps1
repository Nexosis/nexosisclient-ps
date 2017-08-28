# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "All Session Tests" -Tag 'Unit' {
	Context "Integration tests" {
		Set-StrictMode -Version latest

        BeforeAll {
            # Store config values
            $script:DefaultPageSize = (Get-NexosisConfig).DefaultPageSize
            $script:ApiKey = (Get-NexosisConfig).ApiKey
            $script:ApiBaseUrl = (Get-NexosisConfig).ApiBaseUrl
        }

        It "should temporarily change the API Key" {
            Set-NexosisConfig -ApiKey '123456789012345678901234567890ab'
            ((Get-NexosisConfig).ApiKey) | should be '123456789012345678901234567890ab'
        }

        It "should temporarily change the default page size" {
            Set-NexosisConfig -DefaultPageSize 101
            ((Get-NexosisConfig).DefaultPageSize) | should be 101
        }

        It "should temporarily change the " {
            Set-NexosisConfig -ApiBaseUrl 'https://test.url'
            ((Get-NexosisConfig).ApiBaseUrl) | should be 'https://test.url'
        }

        It "should throw exception with invalid API Key" {
            { Set-NexosisConfig -ApiKey abc } | Should throw "Invalid format. Parameter -ApiKey must be a string of 32 alphanumeric characters."
        }

        It "should throw with invalid default page size" {
            { Set-NexosisConfig -DefaultPageSize 12321 } | should throw "Parameter -DefaultPageSize must be an integer between 1 and 1000."
        }

        It "should throw with invalid formatted URL" {
            { Set-NexosisConfig -ApiBaseUrl "badurl" } | should throw "Parameter -BaseUrl must be formatted as a URL."
        }

        AfterAll {
            # Restore config values
            Set-NexosisConfig -ApiKey $script:ApiKey
            Set-NexosisConfig -ApiBaseUrl $script:ApiBaseUrl
            Set-NexosisConfig -SetApiKeyFromEnvironment
        }
    }
}