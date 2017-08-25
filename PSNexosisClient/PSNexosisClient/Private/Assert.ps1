
function assert {
    param(
        [Parameter(Mandatory=$true)]
        [bool]$test,
        [Parameter(Mandatory=$true)]
        [string]$message
    )

    if($test -eq $true) { return }

    $stack = Get-PSCallStack
    $line = ($stack[0].InvocationInfo.Line -replace 'assert','').Trim()
    $num = ($stack[0].ScriptLineNumber)

    throw "Assertion failed $line at line $num : $message"
}