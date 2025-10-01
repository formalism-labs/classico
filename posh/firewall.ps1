
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
        if (Get-NetFirewallRule -Enabled True -Direction Inbound -Action $Action |
            Get-NetFirewallPortFilter |
            Where-Object { $_.Protocol -eq $Protocol -and $_.LocalPort -eq "$Port" }) {
            return
        }

		New-NetFirewallRule -Name $Name -DisplayName $DisplayName `
			-Enabled True -Direction Inbound -Protocol $Protocol `
			-Action $Action -LocalPort $Port
    }
    finally {
        $ProgressPreference = $progress
    }
}

#----------------------------------------------------------------------------------------------
