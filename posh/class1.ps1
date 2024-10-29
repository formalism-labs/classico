
class Class1 {
	[string] $name
	
#	hidden Class1([string] $name_) {
#		$this.name = $name_
#	}
	
	static [Class1] from_x([string] $x) {
		$self = New-Object Class1
		$self.name = $x
		return $self
	}
	
	static [Class1] from_y([string] $y) {
		$self = New-Object Class1
		$self.name = $y
		return $self
	}

	[String] foo([String] $arg1, [String] $arg2) {
		return "$($this.name) '$arg1' '$arg2'"
	}

	[String] bar([Object] $args) {
		return "$($this.name) '$($args.arg1)' '$($args.arg2)'"
	}
}
