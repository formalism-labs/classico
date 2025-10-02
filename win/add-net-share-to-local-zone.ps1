param(
    [Parameter(Mandatory=$true)]
    [string]$SharePath  # e.g. \\server\share
)

# Extract server name from the UNC path
if ($SharePath -match "^\\\\([^\\]+)\\?") {
    $server = $matches[1]
} else {
    Write-Error "Invalid UNC path: $SharePath"
    exit 1
}

$baseKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\$server"

if (-not (Test-Path $baseKey)) {
    New-Item -Path $baseKey -Force | Out-Null
}

# Set Local Intranet Zone for file protocol (value 1)
Set-ItemProperty -Path $baseKey -Name "file" -Value 1 -Type DWord

# Write-Host "✅ Added $SharePath (server: $server) to Local Intranet Zone (system-wide)"
