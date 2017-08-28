Add-Type -TypeDefinition @"
[System.FlagsAttribute]
public enum ViewDeleteOptions
{
    None = 0,
    Sessions = 1
}
"@

Function Remove-NexosisView {
<# 
.Synopsis
Remove a view definition

.Description
Remove a view definition

.Parameter ViewName
Name of the view from which to remove.

.Parameter CascadeOption
Options for cascading the delete.
When None, only deletes the view definition.
When Sessions, deletes view definition and sessions using that view are also deleted.

.Example
# Remove the view named 'salesview'
Remove-NexosisView -viewName 'salesview'

.Example
# Remove the view definition named 'salesview' and delete all associated sessions
Remove-NexosisView -viewName 'salesview' -cascadeOption CascadeSession

.Example
# Get all view definitions that match the partial name 'sales' and delete them.
(Get-NexosisView -partialName 'sales') | foreach { $_.ViewName } | Remove-NexosisView
#>[CmdletBinding(SupportsShouldProcess=$true)] 
Param(
    [Parameter(ValueFromPipeline=$True, Mandatory=$true)]
    [string]$viewName,
    [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
    [ViewDeleteOptions]$cascadeOption,
    [switch] $Force=$False
)
    process {
        $params = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        
        if ($viewName.Trim().Length -eq 0) { 
            throw "Argument '-ViewName' cannot be null or empty."
        }

        if ($cascadeOption -band [ViewDeleteOptions]::Sessions) { 
            $params.Add('cascade','session')
        }

        if ($pscmdlet.ShouldProcess($viewName)) {
            if ($Force -or $pscmdlet.ShouldContinue("Are you sure you want to permanently delete view definition '$viewName'.", "Confirm Delete?")) {
                Invoke-Http -method Delete -path "views/$viewName" -params $params
            }
        }
    }
}
