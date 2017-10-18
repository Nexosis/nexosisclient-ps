# For build automation to enable verbose
if($env:APPVEYOR_REPO_COMMIT_MESSAGE -match "!verbose")
{
	$VerbosePreference = "continue"
}

Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\PSNexosisClient"

$PSVersion = $PSVersionTable.PSVersion.Major

Describe "All Model Tests" -Tag 'Integration' {
	Context "Integration Tests" {
        Set-StrictMode -Version latest
         
        BeforeAll {
            # import dataset
            $script:dataSetName = 'autompg-regression-ps-integration-test'
            Import-NexosisDataSetFromJson -dataSetName $script:dataSetName -jsonFilePath 'auto-mpg.data.json'
        }

        It "creates a new model" {			
            # Create new dataset
            $result = Start-NexosisModelSession -dataSourceName $script:dataSetName -targetColumn mpg -predictionDomain Regression

            "Monitoring session $($result.sessionid)." | Write-Host
            $sessionStatus = Get-NexosisSessionStatus -SessionId $result.SessionID
            
            # Loop / Sleep while we wait for model and predictions to be generated
            while ($sessionStatus -eq 'Started' -or $sessionStatus -eq "Requested") {
                Start-Sleep -Seconds 10
                $sessionStatus = (Get-NexosisSessionStatus -SessionId $result.sessionID)
            }

            $completedResult = Get-NexosisSessionResult -SessionId $result.sessionId
            $script:modelId = $completedResult.ModelId
            $script:sessionId = $completedResult.sessionId
        }

        It "should return a list of models by DataSourceName" {
            $actual = Get-NexosisModel -dataSourceName "$script:dataSetName"
            $actual.predictionDomain | Should Match "regression"
            $actual.sessionId | Should Match $script:sessionId
            $actual.dataSourceName  | Should Match $script:dataSetName
        }

        It "should return model detail by DataSourceName" {
            $actual = Get-NexosisModelDetail -ModelId $script:modelId
            $actual.predictionDomain | Should Match "regression"
            $actual.sessionId | Should Match $script:sessionId
            $actual.dataSourceName  | Should Match $script:dataSetName
         }

        It "should error on getting a non-existant model" {
            $badModelId = [Guid]::NewGuid()
            { Get-NexosisModelDetail -ModelId $badModelId } | should throw "Item of type model with identifier $badModelId was not found"           
        }

        It "should error on removing a non-existant model" {
            $badModelId = [Guid]::NewGuid()
            { Remove-NexosisModel -ModelId $badModelId -force } | should throw "Item of type model with identifier $badModelId was not found"           
        }

        It "should make predictions" {
            $data = @(
                @{
                    Make = "plymouth"
                    Origin = "1"
                    Weight  = "3430"
                    Cylinders = "6"
                    ModelYear = "78"
                    Horsepower = "100"
                    Acceleration = "17.2"
                    Displacement = "225"
                },
                 @{
                    Make = "plymouth"
                    Origin = "1"
                    Weight  = "3200"
                    Cylinders = "6"
                    ModelYear = "80"
                    Horsepower = "90"
                    Acceleration = "15.2"
                    Displacement = "200"
                }
            )

            $results = Invoke-NexosisPredictTarget -modelId $script:modelId -data $data
            $results.data | Should Not Be $null
            $results.data.Count | Should Be 2
            $results.modelId | should be $script:modelId
            $results.sessionId | should be $script:sessionId
            $results.predictionDomain | Should be "regression"
            $results.dataSourceName | should be $script:dataSetName
        }
		
        AfterAll {
            Remove-NexosisDataSet -dataSetName $script:dataSetName -force
        }
    }
}