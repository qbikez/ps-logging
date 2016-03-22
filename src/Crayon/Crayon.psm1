$t = measure-command {
#$helpersPath = (Split-Path -parent $MyInvocation.MyCommand.Definition);
$helpersPath = $PSScriptRoot

#$DebugPreference = "SilentlyContinue"
#if ($env:ChocolateyEnvironmentDebug -eq 'true') {$DebugPreference = "Continue";}

 $t = measure-command {
    [Reflection.Assembly]::LoadFile("$PSScriptRoot\lib\Crayons.dll")
 }
 #write-host "[Crayon:crayon.dll] $t"

$t = measure-command {
# grab functions from files
    @("$helpersPath\functions\log.ps1") | 
    % { . "$_" }
}
#write-host "[Crayon:functions] $t"

 $t = measure-command {

Export-ModuleMember -Function `
    Write-LogVerbose, Write-LogInfo, Write-Logprogress, Write-Logwarn, Write-Logerror, Write-Logmessage, Write-Logtime `
    -Alias *
 }
 #write-host "[Crayon:export] $t"
 
}
 
 #write-host "[Crayon:END] $t"