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
			theColumnName=@{
				alias="columnAlias"
			}
        }
    }, 
    @{
        name="rightDataSet2"
        columnOptions=@{
			columnNameA=@{
				alias="columnAliasA"
			}
			columnNameB=@{
				alias="columnAliasB"
			}
		}
    }
)

# body that should output from the test object above
$testBody = @"
{
    "dataSetName": "dataSetName",
    "joins": [{
            "columnOptions": {
                "theColumnName": {
                    "alias": "columnAlias"
                }
            },
            "joins": null,
            "dataSet": {
                "name": null
            }
        },
        {
            "columnOptions": {
                "columnNameB": {
                    "alias": "columnAliasB"
                },
                "columnNameA": {
                    "alias": "columnAliasA"
                }
            },
            "joins": null,
            "dataSet": {
                "name": null
            }
        }
    ]
}
"@


$testBodyWithColumnsMetaData = @"
{
    "columns": {
        "sales": {
            "imputation": "zeroes",
            "aggregation": "sum",
            "dataType": "numeric",
            "role": "target"
        },
        "timestamp": {
            "imputation": "zeroes",
            "aggregation": "sum",
            "dataType": "date",
            "role": "timestamp"
        },
        "isPromo": {
            "imputation": "zeroes",
            "aggregation": "sum",
            "dataType": "numeric",
            "role": "feature"
        },
        "transactions": {
            "imputation": "zeroes",
            "aggregation": "sum",
            "dataType": "numeric",
            "role": "none"
        }
    },
    "dataSetName": "dataSetName",
    "joins": [{
            "columnOptions": {
                "theColumnName": {
                    "alias": "columnAlias"
                }
            },
            "joins": null,
            "dataSet": {
                "name": null
            }
        },
        {
            "columnOptions": {
                "columnNameB": {
                    "alias": "columnAliasB"
                },
                "columnNameA": {
                    "alias": "columnAliasA"
                }
            },
            "joins": null,
            "dataSet": {
                "name": null
            }
        }
    ]
}
"@

Describe "New-View" -Tag 'Unit' {
	Context "Unit Tests" {
		Set-StrictMode -Version latest
		
		BeforeAll {
			$moduleVersion = (Test-ModuleManifest -Path $PSScriptRoot\..\..\PSNexosisClient\PSNexosisClient.psd1).Version
			$TestVars = @{
				ApiKey       = $Env:NEXOSIS_API_KEY
				UserAgent	 = "Nexosis-PS-API-Client/$moduleVersion"
				ApiEndPoint	 = 'https://api.uat.nexosisdev.com/v1'
				MaxPageSize  = "1000"
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

		It "puts new view, join with name" {
			New-View -viewName "testnew" -dataSetName "dataSetName" -joins $testJoins
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
				($Body | ConvertFrom-Json | ConvertTo-Json -Depth 6) -eq ($testBody | ConvertFrom-Json | ConvertTo-Json -Depth 6)
			}
        }

		It "calls with the proper HTTP verb" {
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope Context -ParameterFilter {
				$method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Put
			}
		}

		It "puts new view with metadata" {
			$columnsMetaData = @{
				isPromo =  @{
								dataType = "numeric"
								role =  "feature"
								imputation =  "zeroes"
								aggregation =  "sum"
							}
				timestamp =  @{
								  dataType =  "date"
								  role =  "timestamp"
								  imputation =  "zeroes"
								  aggregation =  "sum"
							  }
				sales =  @{
							  dataType =  "numeric"
							  role = "target"
							  imputation =  "zeroes"
							  aggregation =  "sum"
						  }
				transactions =  @{
									 dataType =  "numeric"
									 role =  "none"
									 imputation =  "zeroes"
									 aggregation =  "sum"
								 }
			}
			
			New-View -viewName "testnew" -dataSetName "dataSetName" -joins $testJoins -columnMetaData $columnsMetaData
			Assert-MockCalled Invoke-WebRequest -ModuleName PSNexosisClient -Times 1 -Scope It -ParameterFilter {
				($Body | ConvertFrom-Json | ConvertTo-Json -Depth 5) -eq ($testBodyWithColumnsMetaData | ConvertFrom-Json | ConvertTo-Json -Depth 5)
			}
		}
	}
}
