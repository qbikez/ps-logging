$helpersPath = (Split-Path -parent $MyInvocation.MyCommand.Definition);


#$DebugPreference = "SilentlyContinue"
#if ($env:ChocolateyEnvironmentDebug -eq 'true') {$DebugPreference = "Continue";}

[Reflection.Assembly]::LoadFile("$PSScriptRoot\lib\Crayons.dll")

# grab functions from files
Resolve-Path $helpersPath\functions\*.ps1 | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }



Export-ModuleMember -Function `
    Write-LogVerbose, Write-LogInfo, Write-Logprogress, Write-Logwarn, Write-Logerror, Write-Logmessage, Write-Logtime `
    -Alias *
