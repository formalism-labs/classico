
function Println($text) {
	write-output $text | out-host
}

function Print-Error([string] $text) {
    $color = [Console]::ForegroundColor
    [Console]::ForegroundColor = [ConsoleColor]::Red
    [Console]::Error.WriteLine($text)
    [Console]::ForegroundColor = $color
}

#----------------------------------------------------------------------------------------------

function op([scriptblock] $cmd) {
	if ($NOP) {
		echo $cmd
	} else {
		& $cmd
	}
}
#----------------------------------------------------------------------------------------------

function Get-PS-Version() {
	return $PSVersionTable.PSVersion | & {$ofs=".";"$input"}
}


function Get-NDP-Versions() {
	Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
	Get-ItemProperty -name Version,Release -EA 0 |
	Where { $_.PSChildName -match '^(?!S)\p{L}'} |
	Select PSChildName, Version, Release, @{
	  name="Product"
	  expression={
		  switch -regex ($_.Release) {
			"378389"        { [Version]"4.5" }
			"378675|378758" { [Version]"4.5.1" }
			"379893"        { [Version]"4.5.2" }
			"393295|393297" { [Version]"4.6" }
			"394254|394271" { [Version]"4.6.1" }
			"394802|394806" { [Version]"4.6.2" }
			"460798|460805" { [Version]"4.7" }
			{$_ -gt 460805} { [Version]">4.7" }
		  }
		}
	}
}

function Get-DotNet-Runtimes {
    if (! (Get-Command dotnet -ErrorAction SilentlyContinue)) {
		throw "The 'dotnet' command is not available on this system."
	}

	$sdks = (dotnet --list-runtimes) -split "`n" | ForEach-Object {
		if ($_ -match '(.*) (.*) \[(.*)\]') {
			[PSCustomObject]@{
				Name = $matches[1]
				Version = $matches[2]
				Path    = $matches[3].Trim()
			}
		}
	}

	return $sdks
}

function Get-DotNet-Sdks {
    if (! (Get-Command dotnet -ErrorAction SilentlyContinue)) {
		throw "The 'dotnet' command is not available on this system."
	}

	$sdks = (dotnet --list-sdks) -split "`n" | ForEach-Object {
		if ($_ -match '(.*) \[(.*)\]') {
			[PSCustomObject]@{
				Version = $matches[1]
				Path    = $matches[2].Trim()
			}
		}
	}

	return $sdks
}
function Get-Win-Version() {
	$WinVer = New-Object -TypeName PSObject
	$r = Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion'
	$WinVer | Add-Member -MemberType NoteProperty -Name Major    -Value $r.CurrentMajorVersionNumber
	$WinVer | Add-Member -MemberType NoteProperty -Name Minor    -Value $r.CurrentMinorVersionNumber
	$WinVer | Add-Member -MemberType NoteProperty -Name Version  -Value $r.ReleaseId
	$WinVer | Add-Member -MemberType NoteProperty -Name Build    -Value $r.CurrentBuild
	$WinVer | Add-Member -MemberType NoteProperty -Name Revision -Value $r.UBR
	$WinVer | Add-Member -MemberType NoteProperty -Name ProductName    -Value $r.ProductName
	$WinVer | Add-Member -MemberType NoteProperty -Name DisplayVersion -Value $r.DisplayVersion
	$WinVer
}

#----------------------------------------------------------------------------------------------
