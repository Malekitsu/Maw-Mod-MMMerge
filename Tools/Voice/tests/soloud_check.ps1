# Loads every audio file of a directory with the game's own soloud_x86.dll (the decoder the Lua module uses)
# and reports files it rejects plus the decoded length of each file.
# The DLL is 32-bit, so run this in 32-bit PowerShell:
#   C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -NoProfile -File soloud_check.ps1 -Dll <soloud_x86.dll> -Dir <Data\Voices\NPC> -Out lengths.csv
# Exit code 0 = every file loaded.
param(
    [Parameter(Mandatory = $true)][string]$Dll,
    [Parameter(Mandatory = $true)][string]$Dir,
    [string]$Out = ""
)
$src = @"
using System; using System.Runtime.InteropServices;
public static class SL {
  [DllImport(@"$Dll", CallingConvention=CallingConvention.Cdecl)] public static extern IntPtr Wav_create();
  [DllImport(@"$Dll", CallingConvention=CallingConvention.Cdecl)] public static extern int Wav_load(IntPtr w, string f);
  [DllImport(@"$Dll", CallingConvention=CallingConvention.Cdecl)] public static extern double Wav_getLength(IntPtr w);
  [DllImport(@"$Dll", CallingConvention=CallingConvention.Cdecl)] public static extern void Wav_destroy(IntPtr w);
}
"@
Add-Type -TypeDefinition $src
$files = Get-ChildItem -LiteralPath $Dir -File | Where-Object { $_.Extension -in ".ogg", ".wav" }
$bad = 0
$rows = New-Object System.Collections.Generic.List[string]
$rows.Add("key,seconds,result")
foreach ($f in $files) {
    $w = [SL]::Wav_create()
    $r = [SL]::Wav_load($w, $f.FullName)
    $len = [SL]::Wav_getLength($w)
    [SL]::Wav_destroy($w)
    if ($r -ne 0 -or $len -le 0.2) { $bad++; Write-Output ("REJECTED {0} result={1} length={2}" -f $f.Name, $r, $len) }
    $rows.Add(([string]::Format([Globalization.CultureInfo]::InvariantCulture, "{0},{1:F2},{2}", $f.BaseName, $len, $r)))
}
if ($Out) { $rows | Set-Content -LiteralPath $Out -Encoding ascii }
Write-Output ("{0} files, {1} rejected" -f $files.Count, $bad)
if ($bad -eq 0) { exit 0 } else { exit 1 }
