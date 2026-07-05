# Left-align Start button
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarAl -Type DWord -Value 0

# Search icon only
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name SearchboxTaskbarMode -Type DWord -Value 1

# Restart Explorer
Stop-Process explorer -Force
Start-Process explorer.exe
