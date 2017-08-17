$Verbose = @{}
# For build automation to enable verbose
if($ENV:NCBranchName -notlike "master" -or $env:NCCommitMessage -match "!verbose")
{
	$Verbose.add("Verbose",$True)
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

$jsonGetAnswer = @"
{
    "importId":  "015d7a16-8b2b-4c9c-865d-9a400e01a291",
    "type":  "s3",
    "status":  "completed",
    "dataSetName":  "Location-A",
    "parameters":  {
                       "bucket":  "nexosis-sample-data",
                       "path":  "LocationA.csv",
                       "region":  "us-east-1"
                   },
    "requestedDate":  "2017-07-25T14:11:24.072413+00:00",
    "statusHistory":  [
                          {
                              "date":  "2017-07-25T14:11:24.072413+00:00",
                              "status":  "requested"
                          },
                          {
                              "date":  "2017-07-25T14:11:25.0520692+00:00",
                              "status":  "started"
                          },
                          {
                              "date":  "2017-07-25T14:11:26.5209599+00:00",
                              "status":  "completed"
                          }
                      ],
    "messages":  [

                 ],
    "columns":  {

                },
    "links":  [
                  {
                      "rel":  "data",
                      "href":  "https://api.uat.nexosisdev.com/v1/data/Location-A"
                  }
              ]
}
"@
Describe "Get-Import" -Tag 'Integration' {
	Context "Integration Tests" {
        Set-StrictMode -Version latest
        
        It "loads imports by datasetname filter" {
			Get-Import -dataSetName 'Location-A' -page 0 -pageSize 1 | ConvertTo-Json  -depth 3 | Should Be $jsonGetAnswer
        }       
    }
}