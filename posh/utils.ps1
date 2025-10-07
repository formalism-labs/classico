
#----------------------------------------------------------------------------------------------

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

function With-Env {
    param(
        [Parameter(Mandatory, Position = 0)]
        [hashtable] $vars,
        [Parameter(Mandatory, Position = 1)]
        [ScriptBlock] $script
    )

    # Save values
    $old = @{}
    foreach ($k in $vars.Keys) {
        $old[$k] = (Get-Item "Env:$k" -ErrorAction SilentlyContinue).Value
        Set-Item "Env:$k" $vars[$k]
    }

    try {
		& $script
		$exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Command failed with exit code $exitCode"
        }
    } finally {
        # Restore values
        foreach ($k in $vars.Keys) {
            if ($null -eq $old[$k]) {
                Remove-Item "Env:$k" -ErrorAction SilentlyContinue
            } else {
                Set-Item "Env:$k" $old[$k]
            }
        }
    }
}

#----------------------------------------------------------------------------------------------

function bash([string] $cmd) {
    $bash = "C:\msys64\usr\bin\bash.exe"
	with-env @{ MSYSTEM = "MINGW64"; MSYS = $env:MSYS + ",disable_pcon" } {
		& $bash -l -c "$cmd"
	}
    if ($LASTEXITCODE -ne 0) {
        throw "'$cmd' failed with exit code $LASTEXITCODE"
    }
}

#----------------------------------------------------------------------------------------------
