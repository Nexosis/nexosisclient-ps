# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major
$scriptRoot = $PSScriptRoot

$jsonPostBody = @"
{
    "region":  "us-east-1",
    "path":  "LocationA.csv",
    "columns":  {

                },
    "bucket":  "nexosis-sample-data",
    "dataSetName":  "Location-A"
}
"@

Describe "Import-DataSetFromS3" -Tag 'Unit' {
	Context "Unit Tests" {
		Set-StrictMode -Version latest

		BeforeAll {
			$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\..\..\PSNexosisClient\PSNexosisClient.psd1).Version
            $TestVars = @{
                ApiKey       = $Env:NEXOSIS_API_KEY
				UserAgent	 = "Nexosis-PS-API-Client/$moduleVersion"
				ApiEndPoint	 = 'https://api.uat.nexosisdev.com/v1'
				MaxPageSize  = "1000"
				dsName = 'Location-A'
				bucketName = 'nexosis-sample-data'
				s3path = 'LocationA.csv'
				s3region = 'us-east-1'
            }
		}

		Mock -ModuleName PSNexosisClient Invoke-WebRequest { 
			param($Uri, $Method, $Headers, $ContentType, $Body)
				Write-Verbose $Body
		} -Verifiable

		It "mock is called once" {
			Import-DataSetFromS3 -dataSetName $TestVars.DsName -S3BucketName $TestVars.BucketName -S3BucketPath $TestVars.S3path -S3Region $TestVars.S3region
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context
		}

		It "calls with the proper URI" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/imports/S3"
			}
		}

		It "calls with correct JSON body" {
			# Converting from string to json and back seems to remove 
			# any extra whitespace, formatting, etc. so they compare acutal contents.
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				($Body | ConvertFrom-Json | ConvertTo-Json) -eq ($jsonPostBody | ConvertFrom-Json | ConvertTo-Json)
			}
		}

		It "uses the mock" {
			Assert-VerifiableMocks
		}

		It "calls with the proper HTTP verb" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Post
			}
        }

		It "has proper HTTP headers" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				(
					($Headers.Contains("accept")) -and 
					($Headers.Contains("api-key")) -and
					($Headers.Contains("User-Agent")) -and
					($Headers.Get_Item("accept") -eq 'application/json') -and
					($Headers.Get_Item("api-key") -eq $TestVars.ApiKey) -and
					($Headers.Get_Item("User-Agent") -eq $TestVars.UserAgent)
				)
			}
		}
		
		It "should throw if dataset name is null or empty" {
			{ Import-DataSetFromS3 -dataSetName '    ' -S3BucketName $TestVars.BucketName -S3BucketPath $TestVars.S3path -S3Region $TestVars.S3region }  | should Throw "Argument '-dataSetName' cannot be null or empty."
		}
		
		It "should throw if S3Bucketname name is null or empty" {
			{ Import-DataSetFromS3 -dataSetName $TestVars.DsName -S3BucketName '     ' -S3BucketPath $TestVars.S3path -S3Region $TestVars.S3region }  | should Throw "Argument '-S3BucketName' cannot be null or empty."
		}

		It "should throw if S3BucketPath name is null or empty" {
			{ Import-DataSetFromS3 -dataSetName $TestVars.DsName -S3BucketName $TestVars.BucketName -S3BucketPath '     ' -S3Region $TestVars.S3region }  | should Throw "Argument '-S3BucketPath' cannot be null or empty."
		}

		It "should throw if S3Region name is null or empty" {
			{ Import-DataSetFromS3 -dataSetName $TestVars.DsName -S3BucketName $TestVars.BucketName -S3BucketPath $TestVars.S3path -S3Region '       ' }  | should Throw "Argument '-S3Region' cannot be null or empty."
		}
	}
}
