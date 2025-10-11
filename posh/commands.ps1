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

class RunspaceJob : System.IDisposable {
	[runspace] $Runspace
	[powershell] $PowerShell
	[System.IAsyncResult] $Handle
	[System.Management.Automation.PSDataCollection[psobject]] $Output
	
	RunspaceJob([ScriptBlock] $script, [object[]] $arguments) {
		$this.Runspace = [runspacefactory]::CreateRunspace()
		$this.Runspace.Open()
		
		# Create output collection
		$this.Output = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
		
		# Create PowerShell instance
		$this.PowerShell = [powershell]::Create()
		$this.PowerShell.Runspace = $this.Runspace
		$this.PowerShell.AddScript($script) | Out-Null
		
		# Add arguments if provided
		if ($arguments) {
			foreach ($arg in $arguments) {
				$this.PowerShell.AddArgument($arg) | Out-Null
			}
		}
		
		# Start execution
		$this.Handle = $this.PowerShell.BeginInvoke($this.Output, $this.Output)
	}
	
	[bool] IsCompleted() {
		return $this.Handle.IsCompleted
	}
	
	[void] Stop() {
		if ($this.PowerShell) {
			$this.PowerShell.Stop()
		}
	}
	
	[object] EndInvoke() {
		if ($this.PowerShell) {
			return $this.PowerShell.EndInvoke($this.Handle)
		}
		return $null
	}
	
	Dispose() {
		$this.Stop()
		
		if ($this.PowerShell) {
			try {
				$this.EndInvoke()
			} catch {
				# Ignore errors during cleanup
			}
			$this.PowerShell.Dispose()
		}
		
		if ($this.Runspace) {
			$this.Runspace.Close()
			$this.Runspace.Dispose()
		}
	}
}

#----------------------------------------------------------------------------------------------

function runn_url {
	param(
		[Parameter(Mandatory)]
		[Uri] $Url
	)

	$log = "$env:TEMP\runn.log"
	Remove-Item $log -Force -ErrorAction SilentlyContinue

	$progress = $ProgressPreference
	try {
		$ProgressPreference = 'SilentlyContinue';
			(irm $Url) | iex *> $log  # $null 
			if ($LASTEXITCODE -ne 0) {
			throw "Failed executing script from $Url"
		}
	} catch {
	        Get-Content $log
			throw
	} finally {
		$ProgressPreference = $progress
	}
}

#----------------------------------------------------------------------------------------------
