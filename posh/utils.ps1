
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
