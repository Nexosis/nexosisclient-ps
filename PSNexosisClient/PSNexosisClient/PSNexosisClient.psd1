#
# Module manifest for module 'PSNexosisClient'
#
# Generated by: Jason Montgomery
#
# Generated on: 7/27/2017
@{

# Script module or binary module file associated with this manifest.
RootModule = 'PSNexosisClient.psm1'

# Version number of this module.
ModuleVersion = '2.2.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'ea209222-8a47-4039-b50d-c3fedf9e8c26'

# Author of this module
Author = 'Jason Montgomery'

# Company or vendor of this module
CompanyName = 'Nexosis'

# Copyright statement for this module
Copyright = '(c) 2017 Nexosis, Inc. All rights reserved.'

# Description of the functionality provided by this module
Description = 'PSNexosisClient allows you to work with the Nexosis API through PowerShell functions.'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
#TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Get-NexosisAccountQuotas',
    'Get-NexosisConfig',
    'Get-NexosisContest',
    'Get-NexosisContestant',
    'Get-NexosisContestChampion',    
    'Get-NexosisContestSelection',
    'Get-NexosisDataSet',
    'Get-NexosisDataSetData',
    'Get-NexosisDataSetStatistics',
    'Get-NexosisImport',
    'Get-NexosisModel',
    'Get-NexosisModelDetail'
    'Get-NexosisSession',
    'Get-NexosisSessionAnomalyScore',
    'Get-NexosisSessionClassScore',
    'Get-NexosisSessionConfusionMatrix',
    'Get-NexosisSessionResult',
    'Get-NexosisSessionStatus',
    'Get-NexosisSessionStatusDetail',
    'Get-NexosisView',
    'Get-NexosisViewData',
    'Get-NexosisVocabulary',
    'Get-NexosisVocabularySummary',
    'Import-NexosisDataSetFromAzure',
    'Import-NexosisDataSetFromCsv',
    'Import-NexosisDataSetFromJson',
    'Import-NexosisDataSetFromS3',
    'Import-NexosisDataSetFromUrl',
    'Invoke-NexosisPredictTarget',
    'New-NexosisDataSet',
    'New-NexosisView',
    'Remove-NexosisDataSet',
    'Remove-NexosisModel',
    'Remove-NexosisSession',
    'Remove-NexosisView',
    'Set-NexosisConfig',
    'Start-NexosisForecastSession',
    'Start-NexosisImpactSession',
    'Start-NexosisModelSession'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('MachineLearning','api','PSNexosisClient','api-client','powershell')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/Nexosis/nexosisclient-ps/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/Nexosis/nexosisclient-ps'

        # A URL to an icon representing this module.
        IconUri = 'https://avatars2.githubusercontent.com/u/15932631?v=4&s=200'

        # ReleaseNotes of this module
        ReleaseNotes = 'Added support for joining Views with Calendar Data Sources and misc bug fixes.'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'http://docs.nexosis.com/clients/powershell'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

