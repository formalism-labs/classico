
#----------------------------------------------------------------------------------------------

class Path {
    [string] $path

    Path([object] $path) {
		$t = $path.GetType().Name
		if ($t -eq "PathInfo") {
			$this.path = $path.Path
		} elseif ($t -eq "String") {
			$this.path = $path
		}
    }

	static [Path] op_Division([Path] $path, [string] $dir) {
        return [Path]::new($path.path + "/" + $dir)
    }
	
	[string] ToString() {
		return $this.path
	}
}

function path([object] $p) {
	return [Path]::new($p)
}

#----------------------------------------------------------------------------------------------

function mkdir_p([string] $path) {
	New-Item -ItemType Directory -Path $path -Force
}

#----------------------------------------------------------------------------------------------

function rm_rf([string] $path) {
	New-Item -ItemType Directory -Path $path -Force
}

#----------------------------------------------------------------------------------------------
