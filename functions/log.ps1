
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
$p.Add(":(?<cyan>[^\s.]+)", "debug values")

$global:logPattern = $p
$global:logprefix = $null
$global:lastprefix = $null

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


function Log-Result ($message) {
    Log-Info $message
}

function Log-Info ($message)
{
    if (!($message -match "^info")) { $message = "info: " + $message }
    $message = $p.Colorize($message)
    [Crayons.Crayon]::Write($message)
    #Write-Host $message
}

function log-warn($message) {
   if (!($message -match "^warn")) { $message = "warn: " + $message }
   $message = $p.Colorize($message)
   [Crayons.Crayon]::Write($message)
}

function log-error($message) {
   if (!($message -match "^err")) { $message = "err : " + $message }
   $message = $p.Colorize($message)
   [Crayons.Crayon]::Write($message)
}

function Log-Verbose($message, $verbref)
{    
    $VerbosePreference = $verbref
    if (!($message -match "^verbose")) { $message = "verbose: " + $message }
    $message = $p.Colorize($message)
    #$message.WriteToConsole($verboseWriter)
    $message.WriteToConsole()
}

function log-message($message, $prefix) {
    if ($prefix -eq $null) {
        if ($global:logprefix -ne $null) {
            $prefix = $global:logprefix
        } elseif ($global:lastprefix -ne $null) {
            $prefix = $global:lastprefix
        }        
    } else {
        $global:lastprefix = $prefix
    }
    if ($prefix -ne $null) {
        if (!($message -match "^$prefix")) { $message = "$($prefix): " + $message }
    }

   
   $message = $p.Colorize($message)
   $message.WriteToConsole()
}

function Log-Progress($activity, $status, $percentComplete, $id) {
    Write-Progress @PSBoundParameters 
    write-host $activity : $status
}
