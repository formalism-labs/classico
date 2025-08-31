
function install-classico {
	$classico = "$env:LOCALAPPDATA\FormalismLab\classico"
	if (Test-Path -Path $classico) {
		Write-Output "Classico installed in $classico"
		return 1
	}

	push-location

	$tmpdir = ""
	try {
		$tmpdir = New-Item -ItemType Directory -Path (Join-Path -Path $env:TEMP -ChildPath ([System.Guid]::NewGuid().ToString()))
		cd $tmpdir
		irm -O classico-master.zip https://github.com/formalism-labs/classico/archive/refs/heads/master.zip
		Expand-Archive -Path classico-master.zip -DestinationPath . *>$null
		New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\FormalismLab" -Force
		Move-Item -Path classico-master -Destination $classico
		Write-Output "Classico installed in $classico"
	} catch {
		pop-location
		return 1
	} finally {
		if ($tmpdir -ne "" -and (Test-Path -Path $tmpdir)) {
			cd $env:TEMP
			Remove-Item -Path $tmpdir -Recurse -Force
		}
		pop-location
		return 0
	}
}

install-classico
