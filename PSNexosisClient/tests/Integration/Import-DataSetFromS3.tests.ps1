$Verbose = @{}
# For build automation to enable verbose
if($ENV:NCBranchName -notlike "master" -or $env:NCCommitMessage -match "!verbose")
{
	$Verbose.add("Verbose",$True)
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

$dsName = 'Location-A'
$bucketName = 'nexosis-sample-data'
$s3path = 'LocationA.csv'
$s3region = 'us-east-1'

Describe "Import-DataSetFromS3" -Tag 'Integration' {
	Context "Integration Tests" {
        Set-StrictMode -Version latest
        
		It "Imports a file from S3, makes sure it gets correct values" {
            $results = Import-DataSetFromS3 -dataSetName $dsName -S3BucketName $bucketName -S3BucketPath $s3path -S3Region $s3region
            $results.dataSetName | Should Be $dsName
            $results.parameters.bucket | Should Be $bucketName
            $results.parameters.path | Should Be $s3path
            $results.parameters.region | Should Be $s3region
        }
    }
}