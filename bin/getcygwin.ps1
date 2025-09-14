param (
    [switch]$NOP
)

$ROOT = Resolve-Path([System.IO.Path]::Combine($PSScriptRoot, ".."))
$CLASSICO = $ROOT
$POSH = [System.IO.Path]::Combine($ROOT, "posh")

. "$POSH\defs.ps1"

try {
	if (Test-Path "c:\cygwin64" -PathType Container) {
		Print-Error "Cygwin is installed."
		exit 1
	}

	push-location

	$t = $env:temp
	op { irm -outfile $t\cygwin-setup.exe https://www.cygwin.com/setup-x86_64.exe }
	cd c:\
	op { & $t\cygwin-setup.exe }

	$env:CYGWIN = "winsymlinks:native"
	op { & setx CYGWIN "winsymlinks:native" /m }

	$env:HOME = "/home/" + $env:USERNAME
	$env:TZ = "Asia/Tel_Aviv"

	$cygsite = "https://mirror.isoc.org.il/pub/cygwin/"
	# $cygsite = "http://mirrors.kernel.org/sourceware/cygwin"
	$cygpkg = "c:\root\pkg\cygwin"
	$cygroot = "c:\cygwin64"
	$cygpacks = "wget,tar,gawk,bzip2,libiconv"

	mkdir $cygpkg -force
	op { & $t\cygwin-setup.exe --quiet-mode --no-admin --no-desktop --download --local-install --no-verify --site $cygsite --local-package-dir $cygpkg --root $cygroot }
	op { & $t\cygwin-setup.exe --quiet-mode --no-admin --no-desktop --download --local-install --no-verify --site $cygsite --local-package-dir $cygpkg --root $cygroot --packages $cygpacks }
	return

	cp $CLASSICO\win\cygwin\apt-cyg $cygroot\usr\local\bin\
	cp $CLASSICO\win\cygwin\fstab $cygroot\etc\fstab

	op { & $cygroot\usr\bin\bash -l -c true }
	op { & $cygroot\usr\bin\bash -l -c "mkdir -p ~/.local; cd ~/.local; ln -s `$(cygpath '$CLASSICO') ~/.local/classico" }
} catch {
	Print-Error "Error occured during Cygwin installation: $($_.Exception.Message)"
	exit 1
} finally {
	pop-location
}
