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
    "connectionString":  "BlobEndpoint=https://myblobendpoint.blob.core.windows.net/",
    "dataSetName":  "MyAzureDataset",
    "container":  "mycontainer",
    "blob":  "mydatafile.csv"
}
"@

$jsonPostBodyWithColumns = @"
{
    "columns":  {

                },
    "connectionString":  "BlobEndpoint=https://myblobendpoint.blob.core.windows.net/",
    "dataSetName":  "MyAzureDataset",
    "container":  "mycontainer",
    "blob":  "mydatafile.csv"
}
"@

Describe "Import-NexosisDataSetFromAzure" -Tag 'Unit' {
	Context "Unit Tests" {
		Set-StrictMode -Version latest

		BeforeAll {
			$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\..\..\PSNexosisClient\PSNexosisClient.psd1).Version
            $TestVars = @{
                ApiKey       = $Env:NEXOSIS_API_KEY
				UserAgent	 = "Nexosis-PS-API-Client/$moduleVersion"
				ApiEndPoint	 = $Env:NEXOSIS_API_TESTURI
				MaxPageSize  = "1000"
				dsName = 'MyAzureDataset'
				connectionString = 'BlobEndpoint=https://myblobendpoint.blob.core.windows.net/'
				container = 'mycontainer'
				blob = 'mydatafile.csv'
            }
		}

		Mock -ModuleName PSNexosisClient Invoke-WebRequest { 
			param($Uri, $Method, $Headers, $ContentType, $Body, $InFile)
            $response =  New-Object PSObject -Property @{
				StatusCode="200"
				Headers=@{}
				Content=''
			}
			if($Headers['accept'] -eq 'application/json') {
				$response.Content = "{ }"
			} elseif ($Headers['accept'] -eq 'text/csv') {
				$response.Content = "A,B,C,D`r`n1,2,3,4`r`n"
			}
			$response
        } -Verifiable

		It "mock is called once" {
			Import-NexosisDataSetFromAzure -dataSetName $TestVars.DsName -ConnectionString $TestVars.connectionString -container $TestVars.container -blob $TestVars.blob
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context
		}

		It "calls with the proper URI" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/imports/Azure"
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
			Assert-VerifiableMock
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
			{ Import-NexosisDataSetFromAzure -dataSetName '    ' -ConnectionString $TestVars.ConnectionString -container $TestVars.Container -Blob $TestVars.Blob }  | should Throw "Argument '-dataSetName' cannot be null or empty."
		}
		
		It "should throw if Azure ConnectionString name is null or empty" {
			{ Import-NexosisDataSetFromAzure -dataSetName $TestVars.DsName -ConnectionString '    ' -container $TestVars.container -blob $TestVars.blob } | should Throw "Argument '-ConnectionString' cannot be null or empty."
		}

		It "should throw if Container name is null or empty" {
			{ Import-NexosisDataSetFromAzure -dataSetName $TestVars.DsName -ConnectionString $TestVars.connectionString -Container '     ' -blob $TestVars.blob } | should Throw "Argument '-Container' cannot be null or empty."
		}

		It "should throw if Blob name is null or empty" {
			{ Import-NexosisDataSetFromAzure -dataSetName $TestVars.DsName -ConnectionString $TestVars.connectionString -container $TestVars.container -Blob '       ' }  | should Throw "Argument '-Blob' cannot be null or empty."
		}

		It "calls with correct JSON body with columns" {
			Import-NexosisDataSetFromAzure -dataSetName $TestVars.DsName -ConnectionString $TestVars.connectionString -container $TestVars.container -Blob $TestVars.Blob -columns @{}
			# Converting from string to json and back seems to remove 
			# any extra whitespace, formatting, etc. so they compare acutal contents.
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				($Body | ConvertFrom-Json | ConvertTo-Json) -eq ($jsonPostBodyWithColumns | ConvertFrom-Json | ConvertTo-Json)
			}
		}
	}
}
