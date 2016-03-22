$this_script_path = Split-Path -Parent $MyInvocation.MyCommand.Path

$resource_name = "xMongoFirewallRule"
$resource_path = Join-Path -Path $((Get-Item $this_script_path).Parent.FullName) -ChildPath "DSCResources\${resource_name}"

if (! (Get-Module xDSCResourceDesigner))
{
    Import-Module -Name xDSCResourceDesigner
}

if (Get-Module $resource_name)
{
    Remove-Module $resource_name
}

Import-Module "${resource_path}\${resource_name}.psm1"

InModuleScope $resource_name {
    $test_rule_name = "TestRule"
    $test_port = 12345

    $resource_name = $MyInvocation.MyCommand.ScriptBlock.Module.Name

    Describe "${resource_name}, Get-TargetResource" {
        # Hide the real cmdlets / functions
        function Get-NetFirewallPortFilter {}

        Mock Get-NetFirewallRule { $anything = 0; return $anything }
        Mock Get-NetFirewallPortFilter { return @{ LocalPort = $test_port } }

        Get-TargetResource -Name $test_rule_name

        It 'Calls Get-NetFirewallRule with expected arguments' {
            Assert-MockCalled Get-NetFirewallRule -ParameterFilter {
                ($Name -eq $test_rule_name)
            }
        }

        Context 'Rule exists' {
            $returnValue = Get-TargetResource -Name $test_rule_name

            It 'Returns Ensure = Present' {
                $returnValue.Ensure | Should BeExactly "Present"
            }
            It "Returns Port = ${test_port}" {
                $returnValue.Port | Should BeExactly $test_port
            }
        }
        Context "Rule doesn't exist" {
            Mock Get-NetFirewallRule { return $null }

            $returnValue = Get-TargetResource -Name $test_rule_name

            It 'Returns Ensure = Absent' {
                $returnValue.Ensure | Should BeExactly "Absent"
            }
            It 'Returns Port = 0' {
                $returnValue.Port | Should BeExactly 0
            }
        }
    }

    Describe "${resource_name}, Test-TargetResource" {
        Mock Get-TargetResource {}

        Test-TargetResource -Name $test_rule_name

        It 'Calls Get-TargetResource with expected arguments' {
            Assert-MockCalled Get-TargetResource -ParameterFilter {
                ($Name -eq $test_rule_name)
            }
        }

        Context "Rule exists" {
            Mock Get-TargetResource { return @{
                Name = $test_rule_name
                Port = $test_port
                Ensure = "Present"
            } }

            $returnValue = Test-TargetResource -Name $test_rule_name -Port $test_port

            It 'Returns true when rule matches' {
                $returnValue | Should BeExactly $true
            }

            $returnValue = Test-TargetResource -Name $test_rule_name -Port ($test_port + 1)

            It "Returns false when rule doesn't match" {
                $returnValue | Should BeExactly $false
            }

            $returnValue = Test-TargetResource -Name $test_rule_name -Ensure "Absent"

            It 'Returns false when Ensure = Absent' {
                $returnValue | Should BeExactly $false
            }
        }
        Context "Rule doesn't exist" {
            Mock Get-TargetResource { return @{ Ensure = "Absent" } }

            $returnValue = Test-TargetResource -Name $test_rule_name -Ensure "Absent"

            It 'Returns true when Ensure = Absent' {
                $returnValue | Should BeExactly $true
            }

            $returnValue = Test-TargetResource -Name $test_rule_name -Ensure "Present"

            It 'Returns false when Ensure = Present' {
                $returnValue | Should BeExactly $false
            }
        }
    }

    Describe "${resource_name}, Set-TargetResource" {
        Mock New-NetFirewallRule {}
        Mock Set-NetFirewallRule {}
        Mock Remove-NetFirewallRule {}

        Context "Rule exists" {
            Mock Get-TargetResource { return @{ Ensure = "Present" } }

            Set-TargetResource -Name $test_rule_name -Port $test_port

            It 'Calls Set-NetFirewallRule when Ensure is not specified' {
                Assert-MockCalled Set-NetFirewallRule -ParameterFilter {
                    ($Name -eq $test_rule_name) `
                    -and ($Protocol -eq "TCP") `
                    -and ($LocalPort -eq $test_port)
                }
            }
        }
        Context "Rule exists" {
            Mock Get-TargetResource { return @{ Ensure = "Present" } }

            Set-TargetResource -Name $test_rule_name -Port $test_port -Ensure "Present"

            It 'Calls Set-NetFirewallRule when Ensure = Present' {
                Assert-MockCalled Set-NetFirewallRule -ParameterFilter {
                    ($Name -eq $test_rule_name) `
                    -and ($Protocol -eq "TCP") `
                    -and ($LocalPort -eq $test_port)
                }
            }
        }
        Context "Rule exists" {
            Mock Get-TargetResource { return @{ Ensure = "Present" } }

            Set-TargetResource -Name $test_rule_name -Port $test_port -Ensure "Absent"

            It 'Calls Remove-NetFirewallRule when Ensure = Absent' {
                Assert-MockCalled Remove-NetFirewallRule -ParameterFilter {
                    ($Name -eq $test_rule_name)
                }
            }
        }
        Context "Rule doesn't exist" {
            Mock Get-TargetResource { return @{ Ensure = "Absent" } }

            Set-TargetResource -Name $test_rule_name -Port $test_port

            It 'Calls New-NetFirewallRule when Ensure is not specified' {
                Assert-MockCalled New-NetFirewallRule -ParameterFilter {
                    ($Name -eq $test_rule_name) `
                    -and ($Protocol -eq "TCP") `
                    -and ($LocalPort -eq $test_port)
                }
            }
        }
        Context "Rule doesn't exist" {
            Mock Get-TargetResource { return @{ Ensure = "Absent" } }

            Set-TargetResource -Name $test_rule_name -Port $test_port -Ensure "Present"

            It 'Calls New-NetFirewallRule when Ensure = Present' {
                Assert-MockCalled New-NetFirewallRule -ParameterFilter {
                    ($Name -eq $test_rule_name) `
                    -and ($Protocol -eq "TCP") `
                    -and ($LocalPort -eq $test_port)
                }
            }
        }
        Context "Rule doesn't exist" {
            Mock Get-TargetResource { return @{ Ensure = "Absent" } }

            Set-TargetResource -Name $test_rule_name -Port $test_port -Ensure "Absent"

            It 'Does nothing when Ensure = Absent' {
                Assert-MockCalled New-NetFirewallRule -Exactly -Times 0
                Assert-MockCalled Set-NetFirewallRule -Exactly -Times 0
                Assert-MockCalled Remove-NetFirewallRule -Exactly -Times 0
            }
        }
    }
}
