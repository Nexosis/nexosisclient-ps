$ProjectRoot=$PSScriptRoot
$Artifacts = Join-Path $PSScriptRoot "Artifacts"
$BuildNumber = [int][double]::Parse((Get-Date -UFormat %s))
$PercentCompliance = 90

# Synopsis: Clean Artifacts Directory
task Clean BeforeClean, {
    if(Test-Path -Path $Artifacts)
    {
        Remove-Item "$Artifacts/*" -Recurse -Force
    }

    New-Item -ItemType Directory -Path $Artifacts -Force
    Push-Location -Path $Artifacts
    # Temp: Clone since this project is not currently available through PackageManagement
    # NOTE: This will error in PowerShell ISE without -q (stderr or some shit)
    & git clone https://github.com/Xainey/PSTestReport.git -q 
    Pop-Location
}, AfterClean

# Synopsis: Executes before the Clean task
task BeforeClean {}
# Synopsis: Executes after the Clean task
task AfterClean {}
# Synopsis: Executes before the Analyze task
task BeforeAnalyze {}
# Synopsis: Executes after the Analyze task
task AfterAnalyze {}
#  Synopsis: Executes before the Build task
task BeforeBuild {}
#  Synopsis: Executes after the Build task
task AfterBuild {}
# Synopsis: Executes the Build task by simply loading the Powershell Module which will ONLY trigger syntax errors
task Build BeforeBuild, {
    Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
    Import-Module "$PSScriptRoot\PSNexosisClient"
    Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
}, AfterBuild

# Synopsis: Lint Code with PSScriptAnalyzer
task Analyze BeforeAnalyze, {
    $scriptAnalyzerParams = @{
        Path=(Join-Path $PSScriptRoot "\PSNexosisClient\Public\")
        Severity=@('Error', 'Warning')  
    }

    $saResults = Invoke-ScriptAnalyzer @scriptAnalyzerParams -Recurse -Verbose:$false

    # Save Analyze Results as JSON
    $saResults | ConvertTo-Json | Set-Content (Join-Path $Artifacts "ScriptAnalysisResults.json")
    
    if ($saResults) {
        $saResults | Format-Table
        # Removed throw
        Write-Output "One or more PSScriptAnalyzer errors/warnings where found."
    }
}, AfterAnalyze

# Synopsis: Install Build Dependencies
task InstallDependencies {
    # Can't run an Invoke-Build Task without Invoke-Build.
    Install-Module -Name InvokeBuild -Force
    Install-Module -Name Pester -Force
    Install-Module -Name PSScriptAnalyzer -Force
}

# Synopsis: Test the project with Pester. Publish Test and Coverage Reports
task RunAllTests {
   $invokePesterParams = @{
        CodeCoverage=(Join-Path (Join-Path "$PSScriptRoot\PSNexosisClient" "Public") "*.ps1")
    }

    # Publish Test Results as NUnitXml
    $testResults = Invoke-Pester -PassThru @invokePesterParams

    # Save Test Results as JSON
    $testresults | ConvertTo-Json -Depth 5 | Set-Content  (Join-Path $Artifacts "PesterResults.json")

    # Publish Test Report
    $options = @{
        BuildNumber = $BuildNumber
        GitRepo = "Nexosis/PSNexosisClient"
        GitRepoURL = "https://github.com/Nexosis/PSNexosisClient"
        CiURL = "https://build.nexosis.com/job/PSNexosisClient/"
        ShowHitCommands = $false
        Compliance = 0.4
        ScriptAnalyzerFile = (Join-Path $Artifacts "ScriptAnalysisResults.json")
        PesterFile = (Join-Path $Artifacts "PesterResults.json")
        OutputDir = $Artifacts
    }

    . (Join-Path $Artifacts "PSTestReport\Invoke-PSTestReport.ps1") @options
}

task RunIntegrationTests {
    $invokePesterParams = @{
        ExcludeTag=@('Unit') 
        CodeCoverage=(Join-Path (Join-Path "$PSScriptRoot\PSNexosisClient" "Public") "*.ps1")
    }

    # Publish Test Results as NUnitXml
    $testResults = Invoke-Pester -PassThru @invokePesterParams
    Write-Output $testresults
    # Save Test Results as JSON
    $testresults | ConvertTo-Json -Depth 6 | Set-Content  (Join-Path $Artifacts "PesterResults.json")

    # Publish Test Report
    $options = @{
        BuildNumber = $BuildNumber
        GitRepo = "Nexosis/PSNexosisClient"
        GitRepoURL = "https://github.com/Nexosis/PSNexosisClient"
        CiURL = "https://build.nexosis.com/job/PSNexosisClient/"
        ShowHitCommands = $false
        Compliance = 0.4
        ScriptAnalyzerFile = (Join-Path $Artifacts "ScriptAnalysisResults.json")
        PesterFile = (Join-Path $Artifacts "PesterResults.json")
        OutputDir = $Artifacts
    }

    . (Join-Path $Artifacts "PSTestReport\Invoke-PSTestReport.ps1") @options
}

# Synopsis: Test the project with Pester. Publish Test and Coverage Reports
task RunUnitTests {
    $invokePesterParams = @{
        ExcludeTag=@('Integration') 
        CodeCoverage=(Join-Path (Join-Path "$PSScriptRoot\PSNexosisClient" "Public") "*.ps1")
    }

    # Publish Test Results as NUnitXml
    $testResults = Invoke-Pester -PassThru @invokePesterParams

    # Save Test Results as JSON
    $testresults | ConvertTo-Json -Depth 5 | Set-Content  (Join-Path $Artifacts "PesterResults.json")

    # Publish Test Report
    $options = @{
        BuildNumber = $BuildNumber
        GitRepo = "Nexosis/PSNexosisClient"
        GitRepoURL = "https://github.com/Nexosis/PSNexosisClient"
        CiURL = "https://build.nexosis.com/job/PSNexosisClient/"
        ShowHitCommands = $false
        Compliance = 0.4
        ScriptAnalyzerFile = (Join-Path $Artifacts "ScriptAnalysisResults.json")
        PesterFile = (Join-Path $Artifacts "PesterResults.json")
        OutputDir = $Artifacts
    }

    . (Join-Path $Artifacts "PSTestReport\Invoke-PSTestReport.ps1") @options
}

# Synopsis: Throws and error if any tests do not pass for CI usage
task ConfirmTestsPassed {
    # Fail Build after reports are created, this allows CI to publish test results before failing    
    $json = Get-Content (Join-Path $Artifacts "PesterResults.json") | ConvertFrom-Json
    $numberFails = (($json.TestResult | where Result -eq 'failed') | Measure-Object).Count
    assert($numberFails -eq 0) ('Failed "{0}" unit tests.' -f $numberFails)

    # Fail Build if Coverage is under requirement
    $overallCoverage = [Math]::Floor(($json.CodeCoverage.NumberOfCommandsExecuted /
                                      $json.CodeCoverage.NumberOfCommandsAnalyzed) * 100)
    assert($OverallCoverage -gt $PercentCompliance) 
        ('Current Code Coverage: {0}%. Build requirement for build to pass: {1}%.' -f $overallCoverage,
         $PercentCompliance)
}
