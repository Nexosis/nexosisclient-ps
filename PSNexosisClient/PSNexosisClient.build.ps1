$ProjectRoot=$PSScriptRoot
$Artifacts = Join-Path $PSScriptRoot "Artifacts"
$BuildNumber = [int][double]::Parse((Get-Date -UFormat %s))

# Clean Artifacts Directory
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
    # Install Helps package
    Invoke-Expression "& {$((New-Object Net.WebClient).DownloadString('https://github.com/nightroman/PowerShelf/raw/master/Save-NuGetTool.ps1'))} Helps"
    Pop-Location
}, AfterClean

# Executes before the Clean task
task BeforeClean {}

# Executes after the Clean task
task AfterClean {}

# Executes before the Analyze task
task BeforeAnalyze {}

# Executes after the Analyze task
task AfterAnalyze {}

task BeforeBuild {}
task AfterBuild {}

task Build BeforeBuild, {
    Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
    Import-Module "$PSScriptRoot\PSNexosisClient"
    Remove-Module PSNexosisClient -ErrorAction SilentlyContinue
}, AfterBuild

# Lint Code with PSScriptAnalyzer
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

# Install Build Dependencies
task InstallDependencies {
    # Can't run an Invoke-Build Task without Invoke-Build.
    Install-Module -Name InvokeBuild -Force
    Install-Module -Name Pester -Force
    Install-Module -Name PSScriptAnalyzer -Force
}

# Test the project with Pester. Publish Test and Coverage Reports
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
    [xml] $xml = Get-Content (Join-Path $Artifacts "TestResults.xml")
    $numberFails = $xml."test-results".failures
    assert($numberFails -eq 0) ('Failed "{0}" unit tests.' -f $numberFails)

    # Fail Build if Coverage is under requirement
    $json = Get-Content (Join-Path $Artifacts "PesterResults.json") | ConvertFrom-Json
    $overallCoverage = [Math]::Floor(($json.CodeCoverage.NumberOfCommandsExecuted /
                                      $json.CodeCoverage.NumberOfCommandsAnalyzed) * 100)
    assert($OverallCoverage -gt $PercentCompliance) 
        ('A Code Coverage of "{0}" does not meet the build requirement of "{1}"' -f $overallCoverage,
         $PercentCompliance)
}

# TODO: Build and test en-US help
# Helps.ps1 https://www.nuget.org/packages/Helps
task HelpEn {
	$null = mkdir en-US -Force

	. (Join-Path $Artifacts '\Helps\Helps.ps1')
	Convert-Helps Help\Helps-Help.ps1 .\en-US\Helps-Help.xml @{ UICulture = 'en-US' }

	Copy-Item .\en-US\Helps-Help.xml $ScriptRoot\Helps-Help.xml

	Set-Location Help
	Test-Helps Helps-Help.ps1
}

# TODO: View help using the $Culture
task View {
	$file = "$env:TEMP\help.txt"
	[System.Threading.Thread]::CurrentThread.CurrentUICulture = $Culture
	. Helps.ps1
	@(
		'Helps.ps1'
		'Convert-Helps'
		'Merge-Helps'
		'New-Helps'
		'Test-Helps'
	) | .{process{
		'#'*77
		Get-Help $_ -Full | Out-String -Width 80
	}} | Out-File $file
	notepad $file
}