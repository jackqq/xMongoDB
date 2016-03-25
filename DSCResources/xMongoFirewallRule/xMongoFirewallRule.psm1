function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $rule = Get-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue

    if ($rule -ne $null) {
        Write-Verbose "Rule exists."
        $ensureResult = "Present"
        $portFilter = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule
        $portResult = $portFilter.LocalPort
    } else {
        Write-Verbose "Rule does not exist."
        $ensureResult = "Absent"
        $portResult = 0
    }

    return @{
        Name = $Name
        Ensure = $ensureResult
        Port = $portResult
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.UInt16]
        $Port = 27017,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    $result = Get-TargetResource -Name $Name

    if ($result.Ensure -eq "Present") {
        if ($Ensure -eq "Present") {
            Write-Verbose "Update rule."
            Set-NetFirewallRule -Name $Name -Protocol TCP -LocalPort $Port
        } else {
            Write-Verbose "Delete rule."
            Remove-NetFirewallRule -Name $Name
        }
    } else {
        if ($Ensure -eq "Present") {
            Write-Verbose "Add rule."
            New-NetFirewallRule -DisplayName $Name -Name $Name -Protocol TCP -LocalPort $Port
        } else {
            Write-Verbose "Do nothing."
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [System.UInt16]
        $Port = 27017,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present"
    )

    $result = Get-TargetResource -Name $Name

    if ($result.Ensure -eq $Ensure) {
        if ($Ensure -eq "Present") {
            Write-Verbose "Rule exists and is expected so."
            if ($result.Port -eq $Port) {
                Write-Verbose "Port matches."
                return $true
            } else {
                Write-Verbose "Port doesn't match."
                return $false
            }
        } else {
            Write-Verbose "Rule doesn't exist and is expected not."
            return $true
        }
    } else {
        Write-Verbose "Rule's existence is not as expected."
        return $false
    }
}


Export-ModuleMember -Function *-TargetResource

