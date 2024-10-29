param (
    [switch]$NOP
)

$ROOT = Resolve-Path([System.IO.Path]::Combine($PSScriptRoot, ".."))
$CLASSICO = $ROOT
$POSH = [System.IO.Path]::Combine($ROOT, "posh")

. "$POSH\defs.ps1"

Set-ExecutionPolicy Bypass -Scope Process -Force
op { iex "& {$(irm https://community.chocolatey.org/install.ps1)}" }
op { iex "& {$(irm get.scoop.sh)} -RunAsAdmin" }
op { 
    try {
        & choco install winget -y --noprogress
    } catch {}
}
