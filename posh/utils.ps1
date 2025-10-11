
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

class SpinnerRunspace : RunspaceJob {
	SpinnerRunspace() : base({
			$Delay = 100  # ms per frame
			$Frames = @('|', '/', '-', '\')
			
			$i = 0
			try {
				while ($true) {
					$char = $frames[$i % $frames.Length]
					[Console]::Write("`r[$char]")
					Start-Sleep -Milliseconds $delay
					$i++
				}
			} catch {
				[Console]::Write("`r$([char]27)[K")
				# Silently exit when stopped
			}
		},
		@())
	{
		# Spinner-specific initialization
	}
}

function Show-Spinner {
	param (
		[Parameter(Mandatory = $true)]
		[ScriptBlock] $Script
	)

	$spinner = [SpinnerRunspace]::new()
	try {
		$result = & $Script
		
		[Console]::Write("`r$([char]27)[K")
		Write-Host "✔  Done" -ForegroundColor Green
		return $result
		
	} catch {
		[Console]::Write("`r$([char]27)[K")
		Write-Host "✖  Failed:" -ForegroundColor Red
		Write-Host $_.Exception.Message -ForegroundColor Red
		throw
	} finally {
		$spinner.Dispose()
		# Small delay to ensure spinner stops cleanly
		Start-Sleep -Milliseconds 50
	}
}

#----------------------------------------------------------------------------------------------
