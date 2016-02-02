
$asm = [Reflection.Assembly]::LoadFile("$PSScriptRoot\..\lib\Crayons.dll")

$p = new-object -type Crayons.Patterns.Pattern
$p.Add("(?<magenta>'.*')", "colorize quoted names")


[Crayons.CrayonString]::EscapeChar = '`'

[Crayons.Crayon]::Configure({
    param($text, $color) 
    write-host $text -NoNewline -ForegroundColor $color
}, 
{ param ($text) 
    Write-Host $text
})

function Log-Result ($message) {
    Log-Info $message
}

function Log-Info ($message)
{
    $message = $p.Colorize($message)
    [Crayons.Crayon]::Write($message)
    #Write-Host $message
}

function Log-Verbose($message)
{    
    Write-Verbose $message
}

function Log-Progress($activity, $status, $percentComplete, $id) {
    Write-Progress @PSBoundParameters 
    write-host $activity : $status
}
