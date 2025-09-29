
function Println($text) {
	write-output $text | out-host
}

function Print-Error([string] $text) {
    $color = [Console]::ForegroundColor
    [Console]::ForegroundColor = [ConsoleColor]::Red
    [Console]::Error.WriteLine($text)
    [Console]::ForegroundColor = $color
}

Set-Alias -Name EPrint -Value Print-Error

#----------------------------------------------------------------------------------------------

function op([scriptblock] $cmd) {
	if ($NOP) {
		echo $cmd
	} else {
		& $cmd
	}
}

#----------------------------------------------------------------------------------------------

function is_command([string] $cmd) {
	return (get-command $cmd -erroraction SilentlyContinue) -ne $null
}

#----------------------------------------------------------------------------------------------

class Path {
    [string] $path

    Path([object] $path) {
		$t = $path.GetType().Name
		if ($t -eq "PathInfo") {
			$this.path = $path.Path
		} elseif ($t -eq "String") {
			$this.path = $path
		}
    }

	static [Path] op_Division([Path] $path, [string] $dir) {
        return [Path]::new($path.path + "/" + $dir)
    }
	
	[string] ToString() {
		return $this.path
	}
}

function path([object] $p) {
	return [Path]::new($p)
}

#----------------------------------------------------------------------------------------------

function mkdir_p([string] $path) {
	New-Item -ItemType Directory -Path $path -Force
}

#----------------------------------------------------------------------------------------------

function rm_rf([string] $path) {
	New-Item -ItemType Directory -Path $path -Force
}

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
