
#$asm = [Reflection.Assembly]::LoadFile("$PSScriptRoot\..\lib\Crayons.dll")

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
$global:logtooutput = $false
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

function _crayonwrite($message) {
   $cmessage = $p.Colorize($message)
   [Crayons.Crayon]::Write($cmessage)
   if ($logtooutput) { write-output $message } 
}

function WithLogRedirect {
    param([ScriptBlock] $scriptblock) 

    $old = $global:logtooutput 
    try {        
        $global:logtooutput = $true
        Invoke-Command $scriptblock
    } finally {
        $global:logtooutput = $old
    }
}

function Write-LogResult ([Parameter(ValueFromPipeline=$true)] $message) {
    Write-LogInfo $message
}

function Write-LogInfo ([Parameter(ValueFromPipeline=$true)] $message)
{
    if (!($message -match "^info")) { $message = "info: " + $message }
    _crayonwrite($message)
}

function Write-LogWarn([Parameter(ValueFromPipeline=$true)] $message) {
   if (!($message -match "^warn")) { $message = "warn: " + $message }
   _crayonwrite($message)
}

function Write-LogError([Parameter(ValueFromPipeline=$true)] $message) {
   if (!($message -match "^err")) { $message = "err : " + $message }
   _crayonwrite($message)
}

function Write-LogVerbose([Parameter(ValueFromPipeline=$true)] $message, $verbref)
{    
    $VerbosePreference = $verbref
    if (!($message -match "^verbose")) { $message = "verbose: " + $message }
    #$message = $p.Colorize($message)
    #$message.WriteToConsole($verboseWriter)
    #$message.WriteToConsole()
    _crayonwrite($message)
}

function _Write-Logmessage([Parameter(ValueFromPipeline=$true)] $message, $prefix, $condition = $null) {
    if ($condition -ne $null) {
        if ($condition -eq [System.Management.Automation.ActionPreference]::SilentlyContinue `
        -or $condition -eq [System.Management.Automation.ActionPreference]::Ignore) {
            return
        }
    }
    if ($prefix -ne $null) {
        if (!($message -match "^$prefix")) { $message = "$($prefix): " + $message }
    }
    #$message = $p.Colorize($message)
    #$message.WriteToConsole()
    _crayonwrite($message)
}

function Write-Logmessage([Parameter(ValueFromPipeline=$true)] $message, $prefix) {
    if ($prefix -eq $null) {
        if ($global:logprefix -ne $null) {
            $prefix = $global:logprefix
        } elseif ($global:lastprefix -ne $null) {
            $prefix = $global:lastprefix
        }        
    } else {
        $global:lastprefix = $prefix
    }
    

    _Write-Logmessage $message $prefix  
}

function Write-LogTime {
[cmdletbinding()]
param(
    [Parameter(ValueFromPipeline=$true)][scriptblock] $expression, 
    [Alias("m")]
    [string]$message,
    [switch][bool] $detailed = $true
)     
    $pref = $global:timepreference
    if ($VerbosePreference -ne "SilentlyContinue") { $pref = $VerbosePreference }
    if ($detailed) { _Write-Logmessage "$($message)..." -prefix "time" -condition $pref }
    $time = measure-command -Expression $expression 
    _Write-Logmessage "$($message): '$($time.Tostring())'" -prefix "time" -condition $pref
}

function Write-LogProgress($activity, $status, $percentComplete, $id) {
    Write-Progress @PSBoundParameters 
    write-host $activity : $status
}


function get-ElapsedTime([switch][bool]$reset) {
	if ($script:startTs -eq $null -or $reset) { 
		$script:startTs = [DateTimeOffset]::Now 
		$script:lastActivity = $null
		$script:lasttimestamp = $null
	}
    $now = [DateTimeOffset]::Now
    $elapsed = ($now - $script:startTs)   
    return $elapsed
}

function get-loopTime() {
    $e = get-elapsedtime
    if ($script:lasttimestamp -eq $null) { $script:lasttimestamp = $script:startTs }
    $now = [DateTimeOffset]::Now

    $elapsed = ($now - $script:lasttimestamp)   

    $script:lasttimestamp = $now

    return $elapsed
}

function get-ETA($percentComplete) {
    $elapsed = (get-elapsedtime).TotalMilliseconds
    if ($percentComplete -eq 0) { return [timespan]::MaxValue }
    $rate = $percentComplete / $elapsed
    $percleft = 100 - $percentComplete
    $msLeft = $percleft / $rate
    return [Timespan]::FromMilliseconds($msLeft)
}

function Write-ProgressReport($activity, $status, $collection, [switch][bool]$writeToHost, [switch][bool]$complete) {
    if ($script:lastActivity -ne $activity) {
        $script:activitystart = [DateTimeOffset]::Now
        $script:loopC = 0
    }
    $script:lastActivity = $activity
    $script:loopC++
    $c = $script:loopC
    if ($collection -ne $null) {
        $perc = ($c/[float]$collection.count * 100)
        $eta = get-eta $perc
    } else {
        $perc = 0
        $eta = $null
    }
    if ($status -eq $null) { $status = "..." }
    $looptime = get-looptime 
    $a = @{
        Activity = "$activity $c/$($collection.count) Elapsed=$(get-elapsedtime) ETA=$eta Cur Speed=$(1/$($looptime.totalSeconds))/s AVG Speed=$($c/([DateTimeOffset]::Now - $script:activitystart).totalSeconds)/s"
        Status = $status     
    }
    if ($complete) {
     $a += @{ Complete = $true }
    } else {
       $a += @{ PercentComplete = $perc }
    }
    write-progress @a


    if ($writeToHost) {
        $msg = "$activity : $status"
        if ($complete) {
         $msg += " DONE"
        } else {
         $msg += "($($perc)%)"
        }
        write-host $msg
    }
    
}


new-alias Log-Time Write-LogTime
new-alias Log-Result Write-LogResult
new-alias Log-Info Write-LogInfo
new-alias Log-Error Write-LogError
new-alias Log-Message Write-LogMessage
new-alias Log-Verbose Write-LogVerbose
new-alias Log-Progress Write-LogProgress
new-alias Log-Warn Write-LogWarn
new-alias Report-Progress Write-ProgressReport