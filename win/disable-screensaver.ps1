Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'ScreenSaveActive' -Value '0'

# Set the screensaver timeout to 0 (optional)
# Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'ScreenSaveTimeOut' -Value '0'

# Set the screen timeout to never turn off when plugged in (0 means never)
powercfg /change monitor-timeout-ac 0

# Set the screen timeout to never turn off when on battery (0 means never)
powercfg /change monitor-timeout-dc 0

# Disable sleep when plugged in
powercfg /change standby-timeout-ac 0
