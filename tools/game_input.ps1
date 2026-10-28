# Drives the running original client (window class TForm1, "WLO ...") for fidelity research.
#   game_input.ps1 shot  <out.png>
#   game_input.ps1 click <x> <y> [right]      (client-area coordinates, 0,0 = top-left of the game view)
#   game_input.ps1 dblclick <x> <y>           (two clicks inside the system double-click time)
#   game_input.ps1 bgclick <x> <y> [right]    (background: posts mouse messages, the game window is NOT brought to the front)
#   game_input.ps1 vclick <x> <y> [right]     (virtual cursor: needs the Frida GetCursorPos hook, never touches the real mouse/keyboard)
#   game_input.ps1 vmove  <x> <y>
#   game_input.ps1 voff                       (turn the virtual cursor off)
#   game_input.ps1 bgmove  <x> <y>
#   game_input.ps1 bgkey   <name>
#   game_input.ps1 move  <x> <y>
#   game_input.ps1 drag  <x1> <y1> <x2> <y2>
#   game_input.ps1 key   <name>               (F1..F12, ESC, ENTER, SPACE, TAB, UP, DOWN, LEFT, RIGHT, A..Z, 0..9)
#   game_input.ps1 type <text>                (types free text, e.g. a chat line, into the focused game field)
# Claude's own rule: it never uses `type` for account names, passwords or secret codes.
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Command,
    [Parameter(Position = 1)][string]$A1,
    [Parameter(Position = 2)][string]$A2,
    [Parameter(Position = 3)][string]$A3,
    [Parameter(Position = 4)][string]$A4
)

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class W {
    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
    [StructLayout(LayoutKind.Sequential)] public struct PT { public int X, Y; }
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc p, IntPtr l);
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref PT p);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, int dx, int dy, uint d, UIntPtr e);
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr e);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
    [StructLayout(LayoutKind.Sequential)] public struct KI { public ushort vk; public ushort scan; public uint flags; public uint time; public IntPtr extra; public uint pad1; public uint pad2; }
    [StructLayout(LayoutKind.Sequential)] public struct INP { public uint type; public KI ki; }
    [DllImport("user32.dll", SetLastError = true)] public static extern uint SendInput(uint n, INP[] inputs, int size);
    public static void TypeText(string text) {
        foreach (char c in text) {
            var down = new INP { type = 1, ki = new KI { scan = c, flags = 4 } };
            var up = new INP { type = 1, ki = new KI { scan = c, flags = 4 | 2 } };
            SendInput(2, new INP[] { down, up }, Marshal.SizeOf(typeof(INP)));
            System.Threading.Thread.Sleep(25);
        }
    }
    [DllImport("user32.dll")] public static extern bool ScreenToClient(IntPtr h, ref PT p);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    public static IntPtr MakeLParam(int x, int y) { return (IntPtr)((y << 16) | (x & 0xFFFF)); }
    public static string Cls(IntPtr h) { var s = new StringBuilder(256); GetClassName(h, s, 256); return s.ToString(); }
    public static string Txt(IntPtr h) { var s = new StringBuilder(256); GetWindowText(h, s, 256); return s.ToString(); }
}
"@

function Find-GameWindow {
    $script:found = [IntPtr]::Zero
    [W]::EnumWindows({ param($h, $l)
            if ([W]::IsWindowVisible($h) -and [W]::Cls($h) -eq 'TForm1' -and [W]::Txt($h) -like 'WLO*') { $script:found = $h; return $false }
            return $true }, [IntPtr]::Zero) | Out-Null
    return $script:found
}

function Find-Surface($top) {
    # The DirectDraw compatibility window holds the real picture; fall back to the form itself.
    $script:surf = $top
    $pick = { param($h, $l)
        if ([W]::Cls($h) -like 'DDrawCompatPresentation*') { $script:surf = $h; return $false }
        return $true }
    [W]::EnumChildWindows($top, $pick, [IntPtr]::Zero) | Out-Null
    if ($script:surf -eq $top) { [W]::EnumWindows($pick, [IntPtr]::Zero) | Out-Null }
    return $script:surf
}

$top = Find-GameWindow
if ($top -eq [IntPtr]::Zero) { Write-Error 'Game window (TForm1 "WLO ...") not found. Start and log in first.'; exit 2 }
$surf = Find-Surface $top

function To-Screen([int]$x, [int]$y) {
    $p = New-Object W+PT
    $p.X = $x; $p.Y = $y
    [W]::ClientToScreen($surf, [ref]$p) | Out-Null
    return $p
}

function Focus-Game { [W]::ShowWindow($top, 9) | Out-Null; [W]::SetForegroundWindow($top) | Out-Null; Start-Sleep -Milliseconds 150 }

$VK = @{ BACK = 0x08; ESC = 0x1B; ENTER = 0x0D; SPACE = 0x20; TAB = 0x09; LEFT = 0x25; UP = 0x26; RIGHT = 0x27; DOWN = 0x28 }
for ($i = 1; $i -le 12; $i++) { $VK["F$i"] = 0x6F + $i }
foreach ($c in [char[]](48..57 + 65..90)) { $VK["$c"] = [int]$c }

switch ($Command.ToLower()) {
    'shot' {
        $r = New-Object W+RECT
        [W]::GetClientRect($surf, [ref]$r) | Out-Null
        $w = $r.R - $r.L; $h = $r.B - $r.T
        $bmp = New-Object System.Drawing.Bitmap $w, $h
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $dc = $g.GetHdc()
        [W]::PrintWindow($surf, $dc, 1) | Out-Null
        $g.ReleaseHdc($dc); $g.Dispose()
        $bmp.Save($A1, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
        Write-Output "saved $A1 ($w x $h)"
    }
    'move' { Focus-Game; $p = To-Screen $A1 $A2; [W]::SetCursorPos($p.X, $p.Y) | Out-Null }
    'click' {
        Focus-Game; $p = To-Screen $A1 $A2
        # Approach with small mouse movements so the game registers hovering (ground clicks need a prior move), then hold the button
        [W]::SetCursorPos($p.X - 6, $p.Y - 4) | Out-Null; Start-Sleep -Milliseconds 80
        [W]::SetCursorPos($p.X, $p.Y) | Out-Null; Start-Sleep -Milliseconds 260
        if ($A3 -eq 'right') { $d = 0x08; $u = 0x10 } else { $d = 0x02; $u = 0x04 }
        [W]::mouse_event($d, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 140; [W]::mouse_event($u, 0, 0, 0, [UIntPtr]::Zero)
    }
    'dblclick' {
        Focus-Game; $p = To-Screen $A1 $A2; [W]::SetCursorPos($p.X, $p.Y) | Out-Null; Start-Sleep -Milliseconds 80
        for ($n = 0; $n -lt 2; $n++) {
            [W]::mouse_event(0x02, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 25
            [W]::mouse_event(0x04, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 45
        }
    }
    'vmove' { $p = To-Screen $A1 $A2; Set-Content -Path "$env:TEMP\wlo_vcursor.txt" -Value "1 $($p.X) $($p.Y)" }
    'voff' { Set-Content -Path "$env:TEMP\wlo_vcursor.txt" -Value "0 0 0" }
    'vclick' {
        $p = To-Screen $A1 $A2
        Set-Content -Path "$env:TEMP\wlo_vcursor.txt" -Value "1 $($p.X) $($p.Y)"
        Start-Sleep -Milliseconds 150
        $cp = New-Object W+PT; $cp.X = $p.X; $cp.Y = $p.Y
        [W]::ScreenToClient($top, [ref]$cp) | Out-Null
        $lp = [W]::MakeLParam($cp.X, $cp.Y)
        if ($A3 -eq 'right') { $dn = 0x204; $up = 0x205; $mk = 2 } else { $dn = 0x201; $up = 0x202; $mk = 1 }
        [W]::PostMessage($top, 0x200, [IntPtr]::Zero, $lp) | Out-Null; Start-Sleep -Milliseconds 60
        [W]::PostMessage($top, $dn, [IntPtr]$mk, $lp) | Out-Null; Start-Sleep -Milliseconds 70
        [W]::PostMessage($top, $up, [IntPtr]::Zero, $lp) | Out-Null
        # DDrawCompat's presentation window sits above the form: send the same messages there (surface client coordinates)
        if ($surf -ne $top) {
            $sl = [W]::MakeLParam([int]$A1, [int]$A2)
            [W]::PostMessage($surf, 0x200, [IntPtr]::Zero, $sl) | Out-Null; Start-Sleep -Milliseconds 60
            [W]::PostMessage($surf, $dn, [IntPtr]$mk, $sl) | Out-Null; Start-Sleep -Milliseconds 70
            [W]::PostMessage($surf, $up, [IntPtr]::Zero, $sl) | Out-Null
        }
    }
    'bgclick' {
        $x = [int]$A1; $y = [int]$A2; $lp = [W]::MakeLParam($x, $y)
        if ($A3 -eq 'right') { $dn = 0x204; $up = 0x205; $mk = 2 } else { $dn = 0x201; $up = 0x202; $mk = 1 }
        [W]::PostMessage($top, 0x200, [IntPtr]::Zero, $lp) | Out-Null; Start-Sleep -Milliseconds 40
        [W]::PostMessage($top, $dn, [IntPtr]$mk, $lp) | Out-Null; Start-Sleep -Milliseconds 50
        [W]::PostMessage($top, $up, [IntPtr]::Zero, $lp) | Out-Null
    }
    'bgmove' { $lp = [W]::MakeLParam([int]$A1, [int]$A2); [W]::PostMessage($top, 0x200, [IntPtr]::Zero, $lp) | Out-Null }
    'bgkey' {
        $name = $A1.ToUpper()
        if (-not $VK.ContainsKey($name)) { Write-Error "Unsupported key '$A1'"; exit 3 }
        [W]::PostMessage($top, 0x100, [IntPtr][int]$VK[$name], [IntPtr]1) | Out-Null; Start-Sleep -Milliseconds 40
        [W]::PostMessage($top, 0x101, [IntPtr][int]$VK[$name], [IntPtr]0xC0000001) | Out-Null
    }
    'drag' {
        Focus-Game; $a = To-Screen $A1 $A2; $b = To-Screen $A3 $A4
        [W]::SetCursorPos($a.X, $a.Y) | Out-Null; Start-Sleep -Milliseconds 80
        [W]::mouse_event(0x02, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 120
        [W]::SetCursorPos($b.X, $b.Y) | Out-Null; Start-Sleep -Milliseconds 120
        [W]::mouse_event(0x04, 0, 0, 0, [UIntPtr]::Zero)
    }
    'type' { Focus-Game; [W]::TypeText($A1) }
    'key' {
        $name = $A1.ToUpper()
        if (-not $VK.ContainsKey($name)) { Write-Error "Unsupported key '$A1'"; exit 3 }
        Focus-Game
        [W]::keybd_event([byte]$VK[$name], 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 60
        [W]::keybd_event([byte]$VK[$name], 0, 2, [UIntPtr]::Zero)
    }
    default { Write-Error "Unknown command '$Command'"; exit 1 }
}
