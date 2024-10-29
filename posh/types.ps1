
#----------------------------------------------------------------------------------------------

function typename($x, $is = $null) {
	if ($x -eq $null) {
		if ($is -eq $null) {
			return $null;
		} else {
			return $false;
		}
	}
	if ($is -eq $null) {
		$x.GetType().Name
	} else {
		$x.GetType().Name -eq $is
	}
}

#----------------------------------------------------------------------------------------------

function hash-to-obj($hash, $select = $null) {
	$h = $hash.foreach({[PSCustomObject]$_})
	if ($select -ne $null) {
		$h = $h | select $select
	}
	$h
}

function obj-to-hash([Parameter(ValueFromPipeline)] $InputObject) {
    process {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [Hashtable] -or $InputObject -is [Array]) {
			$InputObject
		} elseif ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) { obj-to-hash $object }
            )

            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) {
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = obj-to-hash $property.Value
            }

            $hash
        } elseif ($InputObject -isnot [string] -and $InputObject -is [object]) {
			$object = $InputObject.PSObject
            $hash = @{}

            foreach ($property in $object.Properties) {
				if ($property.Name -ne "Parent") {
					$hash[$property.Name] = obj-to-hash $property.Value
				}
            }

            $hash
        } else {
            $InputObject
        }
    }
}

#----------------------------------------------------------------------------------------------
