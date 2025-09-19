# Windows Client Configuration for Network Share Access
# Run as Administrator

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

Write-Host "Configuring Windows client for network share access..." -ForegroundColor Green

# Enable Network Discovery and File Sharing
Write-Host "Enabling Network Discovery and File Sharing..." -ForegroundColor Yellow
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes

# Configure SMB Client settings
Write-Host "Configuring SMB Client settings..." -ForegroundColor Yellow
Set-SmbClientConfiguration -RequireSecuritySignature $false -EnableSecuritySignature $true -Confirm:$false
Set-SmbClientConfiguration -EnableMultiChannel $true -Confirm:$false

# Enable necessary Windows services
Write-Host "Starting and configuring required services..." -ForegroundColor Yellow
$services = @(
    "LanmanWorkstation",  # Workstation service
    "LanmanServer",       # Server service (for client functionality)
    "Browser",            # Computer Browser
    "Netlogon"           # Net Logon
)

foreach ($service in $services) {
    try {
        Set-Service -Name $service -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $service -ErrorAction SilentlyContinue
        Write-Host "Service $service configured successfully" -ForegroundColor Gray
    }
    catch {
        Write-Warning "Could not configure service: $service"
    }
}

# Configure Local Security Policy settings via registry
Write-Host "Configuring Local Security Policy settings..." -ForegroundColor Yellow

# Allow insecure guest authentication
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name AllowInsecureGuestAuth -Value 1

# Allow anonymous SID/Name translation
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "TurnOffAnonymousBlock" -Value 0 -Type DWord -Force

# Network security: LAN Manager authentication level (set to Send LM & NTLM responses)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LmCompatibilityLevel" -Value 1 -Type DWord -Force

# Network security: Minimum session security for NTLM SSP (including secure RPC-based) clients
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" -Name "NTLMMinClientSec" -Value 0 -Type DWord -Force

# Network access: Allow anonymous SID/Name translation
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "TurnOffAnonymousBlock" -Value 0 -Type DWord -Force

# Configure network provider order
Write-Host "Configuring network provider order..." -ForegroundColor Yellow
$providerOrder = "RDPNP,LanmanWorkstation,webclient"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\NetworkProvider\Order" -Name "ProviderOrder" -Value $providerOrder -Force

# Enable SMB1 if needed (only if required for legacy systems - not recommended for security)
# Uncomment the following lines only if you need SMB1 for legacy systems
# Write-Host "Enabling SMB1 (Legacy - use with caution)..." -ForegroundColor Red
# Enable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol-Client" -All -NoRestart

# Configure Windows Defender Firewall for Private Networks
Write-Host "Configuring Windows Defender Firewall..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Private -Enabled True
Set-NetConnectionProfile -NetworkCategory Private

# Allow File and Printer Sharing through firewall for Private networks
New-NetFirewallRule -DisplayName "File and Printer Sharing (SMB-In)" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow -Profile Private -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "File and Printer Sharing (NB-Session-In)" -Direction Inbound -Protocol TCP -LocalPort 139 -Action Allow -Profile Private -ErrorAction SilentlyContinue

# Configure credential manager for persistent connections
Write-Host "Configuring credential persistence..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "DisableRestrictedAdmin" -Value 0 -Type DWord -Force

# Test network connectivity function
function Test-NetworkShare {
    param(
        [string]$SharePath
    )
    
    Write-Host "`nTesting connection to: $SharePath" -ForegroundColor Cyan
    
    try {
        if (Test-Path $SharePath) {
            Write-Host "Successfully connected to $SharePath" -ForegroundColor Green
            $items = Get-ChildItem $SharePath -ErrorAction SilentlyContinue | Select-Object -First 5
            if ($items) {
                Write-Host "Sample contents:" -ForegroundColor Gray
                $items | Format-Table Name, LastWriteTime -AutoSize
            }
        } else {
            Write-Host "Cannot access $SharePath" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error accessing $SharePath : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nConfiguration completed!" -ForegroundColor Green
Write-Host "Please restart the computer for all changes to take effect." -ForegroundColor Yellow

Write-Host "`nTo test a network share, you can run:" -ForegroundColor Cyan
Write-Host "Test-NetworkShare -SharePath '\\servername\sharename'" -ForegroundColor White

Write-Host "`nTo map a network drive permanently:" -ForegroundColor Cyan
Write-Host "New-PSDrive -Name 'Z' -PSProvider FileSystem -Root '\\server\share' -Persist -Credential (Get-Credential)" -ForegroundColor White

Write-Host "`nFor persistent mapped drives across reboots:" -ForegroundColor Cyan  
Write-Host "net use Z: \\server\share /persistent:yes" -ForegroundColor White

# Optional: Restart required services
Write-Host "`nRestarting network services..." -ForegroundColor Yellow
Restart-Service LanmanWorkstation -Force
Restart-Service LanmanServer -Force

Write-Host "Script execution completed. Reboot recommended." -ForegroundColor Green
