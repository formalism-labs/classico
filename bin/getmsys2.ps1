param (
    [switch] $nop,
    [switch] $NoClassico = $false
)

$ROOT = Resolve-Path([System.IO.Path]::Combine($PSScriptRoot, ".."))
$CLASSICO = $ROOT
$POSH = [System.IO.Path]::Combine($ROOT, "posh")

. "$POSH\defs.ps1"

$f = ""
try {
	if (Test-Path "c:\msys64" -PathType Container) {
		Write-Error "msys2 is installed."
		exit 1
	}

	push-location

	$f = $env:temp/msys2-sfx.exe
	op { irm -outfile $f https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe }
	cd c:\
	op { & $f }

	$env:MSYS = "winsymlinks:native"
	op { setx MSYS "winsymlinks:native" /m }

	$env:HOME = "/home/" + $env:USERNAME
	$env:TZ = Get-IanaTimeZone

	op { & c:\msys64\usr\bin\bash.exe -l -c true }
	if ($NoClassico -eq $true) {
		op { & c:\msys64\usr\bin\bash.exe -l -c "mkdir -p ~/.local; cd ~/.local; ln -s `$(cygpath '$CLASSICO') ~/.local/classico" }
	}
} catch {
	Write-Error "Error during msys2 installation: $($_.Exception.Message)"
	exit 1
} finally {
	pop-location
	op { Remove-Item $f -ErrorAction SilentlyContinue }
}
