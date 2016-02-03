
$asm = [Reflection.Assembly]::LoadFile("$PSScriptRoot\..\lib\Crayons.dll")

$p = new-object -type Crayons.Patterns.Pattern
$p.Add("(?<magenta>'.*?')", "quoted names")
$p.Add("(?<green>info):", "info log level")
$p.Add("(?<cyan>verbose):", "verbose log level")
$p.Add("(?<green>done|OK)", "done")
$p.Add("(?<red>Error|Fail|Failed)", "done")
$p.Add("(?<red>Error:.*)", "errors")

$global:logPattern = $p

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
    if (!($message -match "^error")) { $message = "info: " + $message }
    $message = $p.Colorize($message)
    [Crayons.Crayon]::Write($message)
    #Write-Host $message
}

function Log-Verbose($message, $verbref)
{    
    $VerbosePreference = $verbref
    if (!($message -match "^error")) { $message = "verbose: " + $message }
    $message = $p.Colorize($message)
    #$message.WriteToConsole($verboseWriter)
    $message.WriteToConsole()
}

function Log-Progress($activity, $status, $percentComplete, $id) {
    Write-Progress @PSBoundParameters 
    write-host $activity : $status
}
