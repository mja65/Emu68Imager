rem cd %
rem powershell -ExecutionPolicy Bypass -File PistormImagerGUI.ps1
powershell.exe -Command "& {$wd = Get-Location; Start-Process powershell.exe -Verb RunAs -ArgumentList \"-ExecutionPolicy ByPass -NoExit -Command Set-Location $wd; .\PistormImagerGUI.ps1\"}"
