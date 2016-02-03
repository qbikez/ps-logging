$helpersPath = (Split-Path -parent $MyInvocation.MyCommand.Definition);

write-host "loading module Logging from $helpersPath..."

#$DebugPreference = "SilentlyContinue"
#if ($env:ChocolateyEnvironmentDebug -eq 'true') {$DebugPreference = "Continue";}

[Reflection.Assembly]::LoadFile("$PSScriptRoot\lib\Crayons.dll")

# grab functions from files
Resolve-Path $helpersPath\functions\*.ps1 | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }



Export-ModuleMember -Function `
    Log-Verbose, Log-Info, log-progress, log-warn, log-error, log-message
