$root = $PSScriptRoot
$i = (gi "$root\..\src")
$fp = $i.fullname
write-verbose "adding path of $i '$fp' to psmodulepath"
$env:PSModulePath ="$fp;$env:PSModulePath"