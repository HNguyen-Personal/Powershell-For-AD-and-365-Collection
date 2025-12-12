$taskName = "InstallPrinters"
$scriptSavePath = "$env:ProgramData\IntuneInstalls\Printers"
$PS_ScriptPath = Join-Path -Path $scriptSavePath -ChildPath "InstallPrinters.ps1"
$VBS_ScriptPath = Join-Path -Path $scriptSavePath -ChildPath "run-ps-hidden.vbs"

if (!(Test-Path $scriptSavePath)) {
    New-Item -Path $scriptSavePath -ItemType Directory -Force
}

# Write the printer installation script
@"
Add-Printer -ConnectionName "\\WC-printers\PE_Drama_Copier"
"@ | Set-Content -Path $PS_ScriptPath -Encoding UTF8 -Force

# Write VBScript to hide PowerShell window
@"
Dim shell, fso, file
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
strPath = WScript.Arguments.Item(0)

If fso.FileExists(strPath) Then
  Set file = fso.GetFile(strPath)
  strCMD = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & file.Path & """"
  shell.Run strCMD, 0
End If
"@ | Out-File -FilePath $VBS_ScriptPath -Encoding ASCII -Force

# Create scheduled task
$trigger1 = New-ScheduledTaskTrigger -AtLogOn
$class = Get-CimClass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
$trigger2 = $class | New-CimInstance -ClientOnly
$trigger2.Enabled = $True
$trigger2.Subscription = '<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[Provider[@Name=''Microsoft-Windows-NetworkProfile''] and EventID=10002]]</Select></Query></QueryList>'
$trigger3 = $class | New-CimInstance -ClientOnly
$trigger3.Enabled = $True
$trigger3.Subscription = '<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[Provider[@Name=''Microsoft-Windows-NetworkProfile''] and EventID=4004]]</Select></Query></QueryList>'

$principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" -Id "Author"
$action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\wscript.exe" -Argument "`"$VBS_ScriptPath`" `"$PS_ScriptPath`""
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $taskName -Trigger $trigger1,$trigger2,$trigger3 -Action $action -Principal $principal -Settings $settings -Description "Map network printers on logon and network change" -Force
