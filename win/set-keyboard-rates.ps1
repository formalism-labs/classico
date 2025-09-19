
# Set the keyboard delay (0 = shortest, 3 = longest)
Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value 0

# Set the keyboard speed (0 = slowest, 31 = fastest)
Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value 31

$signature = @"
using System;
using System.Runtime.InteropServices;
public class Keyboard {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(
        uint uiAction,
        uint uiParam,
        IntPtr pvParam,
        uint fWinIni
    );
}
"@

Add-Type $signature

$SPI_SETKEYBOARDDELAY = 0x0017
$SPI_SETKEYBOARDSPEED = 0x000B
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDCHANGE = 0x02

$delay = 0       # 0 (shortest) to 3 (longest)
$speed = 31      # 0 (slowest) to 31 (fastest)

# Apparently, both registry and API are required for it to take effect immediately
[Keyboard]::SystemParametersInfo($SPI_SETKEYBOARDDELAY, $delay, [IntPtr]::Zero, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE) | Out-Null
[Keyboard]::SystemParametersInfo($SPI_SETKEYBOARDSPEED, $speed, [IntPtr]::Zero, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE) | Out-Null
