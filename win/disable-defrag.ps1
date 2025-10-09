
Stop-Service -Name "defragsvc" -Force -ErrorAction SilentlyContinue
Disable-ScheduledTask -TaskName "ScheduledDefrag" -TaskPath "\Microsoft\Windows\Defrag\"
