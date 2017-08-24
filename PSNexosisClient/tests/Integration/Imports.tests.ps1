# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "All Import Tests" -Tag 'Integration' {
    Context "Integration Tests" {
        Set-StrictMode -Version latest
        
        BeforeAll {
            $script:dsName = 'Location-A'
            $script:bucketName = 'nexosis-sample-data'
            $script:s3path = 'LocationA.csv'
            $script:s3region = 'us-east-1'
        }

        It "Imports a file from S3, makes sure it gets correct values" {
            $results = Import-DataSetFromS3 `
                        -dataSetName $script:dsName `
                        -S3BucketName $script:bucketName `
                        -S3BucketPath $script:s3path `
                        -S3Region $script:s3region

            ([Guid]$results.ImportId) | Should BeOfType [Guid]
            
            $results.dataSetName | Should Be $script:dsName
            $results.parameters.bucket | Should Be $script:bucketName
            $results.parameters.path | Should Be $script:s3path
            $results.parameters.region | Should Be $script:s3region
            $script:ImportId = $results.ImportId
        }

        It "loads imports by datasetname filter" {
            $details = Get-Import -dataSetName $script:dsName -page 0 -pageSize 1
            $details.ImportId | Should Be $script:ImportId
            $details.type | Should be  "s3"
            $details.dataSetName | Should be $script:dsName
            $details.status | Should -match "requested|started|completed"
        }

        It "get imports by GUID" {
            $details = Get-Import  $script:ImportId
            $details.ImportId | Should Be $script:ImportId
            $details.type | Should be  "s3"
            $details.dataSetName | Should be $script:dsName
            $details.status | Should -match "requested|started|completed"
        }

        AfterAll {
            # Make sure import is completed before deleting
            do {
                $status = Get-Import -importId $script:ImportId
            } while ($status.status -ne "completed")

            Remove-DataSet -dataSetName $script:dsName -cascadeOption CascadeSessions -force
        }
    }
}