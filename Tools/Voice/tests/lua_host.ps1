# Runs a Lua file inside the game's own LuaJIT (ExeMods\MMExtension\lua51.dll).
# The DLL is 32-bit, so this must run in 32-bit PowerShell:
#   C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -NoProfile -File lua_host.ps1 -Dll <lua51.dll> -Script <file.lua> -Params 'a|b'
# The script is called with the '|'-separated -Params strings as its arguments (...); the string it returns is printed.
# Exit code: 0 = the chunk ran and returned a string starting with "OK", 1 = anything else.
param(
    [Parameter(Mandatory = $true)][string]$Dll,
    [Parameter(Mandatory = $true)][string]$Script,
    [string]$Params = ""
)
$src = @"
using System; using System.Runtime.InteropServices;
public static class L {
  [DllImport(@"$Dll", CallingConvention=CallingConvention.Cdecl)] public static extern IntPtr luaL_newstate();
  [DllImport(@"$Dll", CallingConvention=CallingConvention.Cdecl)] public static extern void luaL_openlibs(IntPtr L);
  [DllImport(@"$Dll", CallingConvention=CallingConvention.Cdecl)] public static extern int luaL_loadfile(IntPtr L, string f);
  [DllImport(@"$Dll", CallingConvention=CallingConvention.Cdecl)] public static extern void lua_pushstring(IntPtr L, string s);
  [DllImport(@"$Dll", CallingConvention=CallingConvention.Cdecl)] public static extern int lua_pcall(IntPtr L, int a, int r, int e);
  [DllImport(@"$Dll", CallingConvention=CallingConvention.Cdecl)] public static extern IntPtr lua_tolstring(IntPtr L, int i, IntPtr len);
}
"@
Add-Type -TypeDefinition $src
$L = [L]::luaL_newstate()
[L]::luaL_openlibs($L)
function Pop-String { [Runtime.InteropServices.Marshal]::PtrToStringAnsi([L]::lua_tolstring($L, -1, [IntPtr]::Zero)) }
if ([L]::luaL_loadfile($L, $Script) -ne 0) { Pop-String; exit 1 }
$list = @(); if ($Params) { $list = $Params -split '\|' }
foreach ($a in $list) { [L]::lua_pushstring($L, $a) }
$rc = [L]::lua_pcall($L, $list.Count, 1, 0)
$out = Pop-String
$out
if ($rc -eq 0 -and $out -like "OK*") { exit 0 } else { exit 1 }
