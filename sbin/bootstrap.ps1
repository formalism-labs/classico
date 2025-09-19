
function install-classico {
	$classico = "$env:LOCALAPPDATA\FormalismLab\classico"
	if (Test-Path -Path $classico) {
		Write-Output "Classico found in ${classico}: not downloading"
		return
	}

	push-location

	$tmpdir = ""
	try {
		$tmpdir = New-Item -ItemType Directory -Path (Join-Path -Path $env:TEMP -ChildPath ([System.Guid]::NewGuid().ToString()))
		cd $tmpdir
		Write-Output "Downloading Classico ..."
		irm -O classico-master.zip https://github.com/formalism-labs/classico/archive/refs/heads/master.zip
		Expand-Archive -Path classico-master.zip -DestinationPath . *>$null
		New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\FormalismLab" -Force
		Move-Item -Path classico-master -Destination $classico
		Write-Output "Classico downloaded into ${classico}"
		cd $env:LocalAppData\Local\FormalismLab\classico\bin
		Write-Output "Installing MSYS2 ..."
		& .\getmsys2.ps1
		Write-Output "Setting up Classico ..."
		& c:\msys64\usr\bin\bash.exe -l -c "~/.local/classico/sbin/setup"
		Write-Output "Done."
	} catch {
		pop-location
		Write-Error "Error downloading Classico"
		return
	} finally {
		if ($tmpdir -ne "" -and (Test-Path -Path $tmpdir)) {
			cd $env:TEMP
			Remove-Item -Path $tmpdir -Recurse -Force
		}
		pop-location
	}
}

install-classico
