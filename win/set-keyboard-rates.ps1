
# Set the keyboard delay (0 = shortest, 3 = longest)
Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value 0

# Set the keyboard speed (0 = slowest, 31 = fastest)
Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value 31
