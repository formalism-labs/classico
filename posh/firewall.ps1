
#----------------------------------------------------------------------------------------------

function New-FirewallRule {
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [int] $Port,

        [string] $DisplayName = $Name,
        [string] $Protocol = 'TCP',
		
		[ValidateSet('Allow', 'Deny')]
        [string] $Action = 'Allow'
    )

    $progress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
    	$rule = Get-NetFirewallRule -Enabled True -Direction Inbound -Action $Action |
		Get-NetFirewallPortFilter |
		Where-Object { $_.Protocol -eq $Protocol -and $_.LocalPort -eq "$Port" }
        if ($rule) {
            return
        }

	New-NetFirewallRule -Name $Name -DisplayName $DisplayName `
		-Enabled True -Action $Action `
		-Direction Inbound -Protocol $Protocol -LocalPort $Port `
		-Profile Any
    }
    finally {
        $ProgressPreference = $progress
    }
}

#----------------------------------------------------------------------------------------------
