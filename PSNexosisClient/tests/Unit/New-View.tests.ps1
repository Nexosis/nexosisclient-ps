# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

# Hashtable of the join definitions
$testJoins = @(
    @{
        name="rightDataSet1"
        columnOptions= @{
			mehColumnName=@{
				alias="columnAlias"
				joinInterval="Day"
			}
        }
    }, 
    @{
        name="rightDataSet2"
        columnOptions=@{
			columnNameA=@{
				alias="columnAliasA"
				joinInterval="Day"
			}
			columnNameB=@{
				alias="columnAliasB"
				joinInterval="Day"
			}
		}
    }
)

# body that should output from the test object above
$testBody = @"
{
    "columns": {

    },
    "dataSetName": "dataSetName",
    "joins": [{
            "columnOptions": {
                "mehColumnName": {
                    "joinInterval": "Day",
                    "alias": "columnAlias"
                }
            },
            "joins": null,
            "dataSet": {
                "dataSetName": null
            }
        },
        {
            "columnOptions": {
                "columnNameB": {
                    "joinInterval": "Day",
                    "alias": "columnAliasB"
                },
                "columnNameA": {
                    "joinInterval": "Day",
                    "alias": "columnAliasA"
                }
            },
            "joins": null,
            "dataSet": {
                "dataSetName": null
            }
        }
    ]
}
"@

Describe "New-View" {
	Context "Unit Tests" {
		Set-StrictMode -Version latest
		
		BeforeEach {
			$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\..\..\PSNexosisClient\PSNexosisClient.psd1).Version
			$TestVars = @{
				ApiKey       = $Env:NEXOSIS_API_KEY
				UserAgent	 = "Nexosis-PS-API-Client/$moduleVersion"
				ApiEndPoint	 = 'https://api.uat.nexosisdev.com/v1'
				MaxPageSize  = "1000"
			}
		}

		Mock -ModuleName PSNexosisClient Invoke-WebRequest { 
            param($Uri, $Method, $Headers, $Body) 
		} -Verifiable

		It "throws if ViewName is null or empty" {
			{ New-View -viewName '' -dataSetName "dataSetName" -joins $testJoins }  | should Throw "Cannot bind argument to parameter 'viewName' because it is an empty string."
		}

		It "throws if ViewName is invalid" {
			{ New-View -viewName '     ' -dataSetName "dataSetName" -joins $testJoins }  | should Throw "Argument '-viewName' cannot be null or empty."
		}

		It "throws if joins is null or empty" {
			{ New-View -viewName 'notnull' -dataSetName "dataSetName" -joins $null}  | should Throw "Cannot bind argument to parameter 'joins' because it is null."
		}

		It "throws if joins paramter is not an array" {
			{ New-View -viewName 'notnull' -dataSetName "dataSetName" -joins "blah"}  | should Throw "Parameter '-joins' must be an array of hashes."
		}

		It "throws if columnMetaData paramter is not an array of hashes" {
			{ New-View -viewName 'notnull' -dataSetName "dataSetName" -joins $testJoins -columnMetaData "string" }  | should Throw "Parameter '-columnMetaData' must be a hashtable of column metadata for the data."
		}

		It "throws exception when dataSetName is invalid" {
			{New-View -viewName 'notnull' -dataSetName '       ' -joins $testJoins } | Should throw "Argument '-DataSetName' cannot be null or empty."
		}

		It "throw exception if joins does not contain at least one join" {
			{ New-View -viewName 'notnull' -dataSetName "dataSetName" -joins @() } | Should throw "Parameter '-joins' must contain at least one join."
		}

		It "puts new view, join and metadata with name" {
			New-View -viewName "testnew" -dataSetName "dataSetName" -joins $testJoins -columnMetaData @{}
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It
		}

		It "calls with the correct URI" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$Uri -eq "$($TestVars.ApiEndPoint)/views/testnew"
			}
        }
		
		It "calls with the correct body" {
			# Converting from string to json and back seems to remove 
			# any extra whitespace, formatting, etc. so they compare acutal contents.
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				($Body | ConvertFrom-Json | ConvertTo-Json -Depth 5) -eq ($testBody | ConvertFrom-Json | ConvertTo-Json -Depth 5)
			}
        }

		It "calls with the proper HTTP verb" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Put
			}
		}
	}
}
