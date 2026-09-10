New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name EnableLinkedConnections -PropertyType DWord -Value 1 -Force
