' Turbo Old PC launcher - no privileges requested
Option Explicit
Dim fso, shell, root, powershell, application, command
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
root = fso.GetParentFolderName(WScript.ScriptFullName)
powershell = shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
application = fso.BuildPath(root, "app\TurboOldPC.ps1")
If Not fso.FileExists(application) Then
  MsgBox "Turbo Old PC files are incomplete. Re-extract the entire ZIP.", vbExclamation, "Turbo Old PC"
  WScript.Quit 1
End If
command = """" & powershell & """ -NoProfile -NoLogo -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & application & """"
shell.Run command, 0, False
