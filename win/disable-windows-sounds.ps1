# Disable Windows system sounds by clearing the default sound scheme
Set-ItemProperty -Path "HKCU:\AppEvents\Schemes\Apps\.Default\.Default\.Current" -Name "(default)" -Value ""

# Optional: also clear .Modified if it exists
Set-ItemProperty -Path "HKCU:\AppEvents\Schemes\Apps\.Default\.Default\.Modified" -Name "(default)" -Value ""
