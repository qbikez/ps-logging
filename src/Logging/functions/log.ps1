
$asm = [Reflection.Assembly]::LoadFile("$PSScriptRoot\..\lib\Crayons.dll")

$p = new-object -type Crayons.Patterns.Pattern
$p.Add("'(?<magenta>.*?)'", "quoted names")
$p.Add("^(?<green>info):", "info log level")
$p.Add("^(?<yellow>warn):", "warn log level")
$p.Add("^(?<red>err) :", "error log level")
$p.Add("^(?<cyan>verbose):", "verbose log level")
$p.Add("(?<green>done|OK)", "done")
$p.Add("(?<red>Error|Fail|Failed)", "done")
$p.Add("(?<red>Error:.*)", "errors")
$p.Add(":(?<cyan>[^\s.\\][^\s.]+)", "debug values")

$global:logPattern = $p
$global:logprefix = $null
$global:lastprefix = $null
if ($global:timepreference -eq $null) {
    [System.Management.Automation.ActionPreference]$global:timepreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
}

[Crayons.CrayonString]::EscapeChar = '`'

[Crayons.Crayon]::Configure({
    param($text, $color) 
    write-host $text -NoNewline -ForegroundColor $color
}, 
{ param ($text) 
    Write-Host $text
})

$verboseBuffer = ""
$verboseWriter = [Crayons.Crayon]::CreateWriter({
    param($text, $color) 
    $verboseBuffer += $text
}, 
{ param ($text) 
    $verboseBuffer += $text
    Write-host $verboseBuffer
    $verbosebuffer = ""
})


function Log-Result ([Parameter(ValueFromPipeline=$true)] $message) {
    Log-Info $message
}

function Log-Info ([Parameter(ValueFromPipeline=$true)] $message)
{
    if (!($message -match "^info")) { $message = "info: " + $message }
    $message = $p.Colorize($message)
    [Crayons.Crayon]::Write($message)
    #Write-Host $message
}

function log-warn([Parameter(ValueFromPipeline=$true)] $message) {
   if (!($message -match "^warn")) { $message = "warn: " + $message }
   $message = $p.Colorize($message)
   [Crayons.Crayon]::Write($message)
}

function log-error([Parameter(ValueFromPipeline=$true)] $message) {
   if (!($message -match "^err")) { $message = "err : " + $message }
   $message = $p.Colorize($message)
   [Crayons.Crayon]::Write($message)
}

function Log-Verbose([Parameter(ValueFromPipeline=$true)] $message, $verbref)
{    
    $VerbosePreference = $verbref
    if (!($message -match "^verbose")) { $message = "verbose: " + $message }
    $message = $p.Colorize($message)
    #$message.WriteToConsole($verboseWriter)
    $message.WriteToConsole()
}

function _log-message([Parameter(ValueFromPipeline=$true)] $message, $prefix, $condition = $null) {
    if ($condition -ne $null) {
        if ($condition -eq [System.Management.Automation.ActionPreference]::SilentlyContinue `
        -or $condition -eq [System.Management.Automation.ActionPreference]::Ignore) {
            return
        }
    }
    if ($prefix -ne $null) {
        if (!($message -match "^$prefix")) { $message = "$($prefix): " + $message }
    }
    $message = $p.Colorize($message)
    $message.WriteToConsole()
}
function log-message([Parameter(ValueFromPipeline=$true)] $message, $prefix) {
    if ($prefix -eq $null) {
        if ($global:logprefix -ne $null) {
            $prefix = $global:logprefix
        } elseif ($global:lastprefix -ne $null) {
            $prefix = $global:lastprefix
        }        
    } else {
        $global:lastprefix = $prefix
    }
    

    _log-message $message $prefix  
}

function log-time {
[cmdletbinding()]
param(
    [Parameter(ValueFromPipeline=$true)][scriptblock] $expression, 
    [Alias("m")]
    [string]$message,
    [switch][bool] $detailed = $true
)     
    $pref = $global:timepreference
    if ($VerbosePreference -ne "SilentlyContinue") { $pref = $VerbosePreference }
    if ($detailed) { _log-message "$($message)..." -prefix "time" -condition $pref }
    $time = measure-command -Expression $expression 
    _log-message "$($message): '$($time.Tostring())'" -prefix "time" -condition $pref
}

function Log-Progress($activity, $status, $percentComplete, $id) {
    Write-Progress @PSBoundParameters 
    write-host $activity : $status
}
