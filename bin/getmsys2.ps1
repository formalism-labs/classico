param (
    [switch]$NOP
)

$ROOT = Resolve-Path([System.IO.Path]::Combine($PSScriptRoot, ".."))
$CLASSICO = $ROOT
$POSH = [System.IO.Path]::Combine($ROOT, "posh")

. "$POSH\defs.ps1"

try {
	if (Test-Path "c:\msys64" -PathType Container) {
		Print-Error "msys2 is installed."
		exit 1
	}

	push-location

	$t = $env:temp
	op { irm -outfile $t/msys2-sfx.exe https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe }
	cd c:\
	op { & $t\msys2-sfx.exe }

	$env:MSYS = "winsymlinks:native enable_pcon"
	op { & setx MSYS "winsymlinks:native enable_pcon" /m }

	$env:HOME = "/home/" + $env:USERNAME
	$env:TZ = "Asia/Tel_Aviv"

	op { & c:\msys64\usr\bin\bash -l -c true }
} catch {
	Print-Error "Error occured during msys2 installation."
	exit 1
} finally {
	pop-location
}
