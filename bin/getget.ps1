param (
	[switch] $UPDATE,
    [switch] $NOP
)

$ROOT = Resolve-Path([System.IO.Path]::Combine($PSScriptRoot, ".."))
$CLASSICO = $ROOT
$POSH = [System.IO.Path]::Combine($CLASSICO, "posh")

. "$POSH\defs.ps1"

if (! ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
	Print-Error "Please run this as Administrator"
	exit 1
}

Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

if (! (is_command "choco")) {
	if (! $UPDATE) {
		op { iex "& {$(irm https://community.chocolatey.org/install.ps1)}" }
	} else {
		op { choco upgrade -y chocolatey }
	}
}
if (! (is_command "scoop")) {
	if (! $UPDATE) {
		op { iex "& {$(irm get.scoop.sh)} -RunAsAdmin" }
	} else {
		# this requires git
		op { scoop update }
	}
}
if (! (is_command "winget")) {
	op { 
		try {
			& choco install winget -y --noprogress
		} catch {}
	}
}
