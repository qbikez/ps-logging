
$asm = [Reflection.Assembly]::LoadFile("$PSScriptRoot\..\lib\Crayons.dll")

$p = [Crayons.Patterns.Pattern]::new(
    "(?<magenta>'.*')"
)

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

Log-Info "testing 'this'"
Log-Info "testing 'that'"
Log-progress -activity "testing this module" -status "running test 1" -percentComplete 59
#write-progress -activity "testing this module" -status "running test 1" -percentComplete 59
Start-Sleep -Seconds 3