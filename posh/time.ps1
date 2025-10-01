
#----------------------------------------------------------------------------------------------

function Get-IanaTimeZone() {
    param(
        [string]$WindowsTimeZoneId = (Get-TimeZone).Id
    )
	
    # Location of the mapping file
    $mapFile = "$env:TEMP\windowsZones.xml"

    # Download CLDR mapping if not cached
    if (-not (Test-Path $mapFile)) {
		$progress = $ProgressPreference
		$ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest `
			-Uri "https://raw.githubusercontent.com/unicode-org/cldr/master/common/supplemental/windowsZones.xml" `
            -OutFile $mapFile
		$ProgressPreference = $progress
    }

    [xml]$xml = Get-Content $mapFile

    # Look up IANA tz with "territory=001" (the canonical mapping)
    $iana = $xml.supplementalData.windowsZones.mapTimezones.mapZone |
        Where-Object { $_.other -eq $WindowsTimeZoneId -and $_.territory -eq "001" } |
        Select-Object -ExpandProperty type -ErrorAction Ignore

    if (-not $iana) {
        Write-Error "No IANA mapping found for Windows timezone '$WindowsTimeZoneId'"
    }

    return $iana
}

#----------------------------------------------------------------------------------------------
