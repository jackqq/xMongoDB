$this_script_path = Split-Path -Parent $MyInvocation.MyCommand.Path

$resource_name = "xMongoFirewallRule"
$resource_path = Join-Path -Path $((Get-Item $this_script_path).Parent.FullName) -ChildPath "DSCResources\${resource_name}"

if (! (Get-Module xDSCResourceDesigner))
{
    Import-Module -Name xDSCResourceDesigner
}

Describe "${resource_name}, the DSC resource" {
    It 'Passes Test-xDscResource' {
        Test-xDscResource $resource_path | Should Be $true
    }

    It 'Passes Test-xDscSchema' {
        Test-xDscSchema "${resource_path}\${resource_name}.schema.mof" | Should Be $true
    }
}

if (Get-Module $resource_name)
{
    Remove-Module $resource_name
}

Import-Module "${resource_path}\${resource_name}.psm1"

Describe "${resource_name}, Integration Tests" {
    $test_rule_name  = "MongoDB Test Rule"
    $test_port = 54321

    Context "Rule doesn't exist" {
        Remove-NetFirewallRule -Name $test_rule_name -ErrorAction SilentlyContinue

        It 'Detects if change is required' {
            Test-TargetResource -Name $test_rule_name -Port $test_port -Ensure "Present" | Should Be $false
            Test-TargetResource -Name $test_rule_name -Port $test_port -Ensure "Absent" | Should Be $true
        }

        It 'Creates the rule' {
            Set-TargetResource -Name $test_rule_name -Port $test_port
            Test-TargetResource -Name $test_rule_name -Port $test_port -Ensure "Present" | Should Be $true
            Remove-NetFirewallRule -Name $test_rule_name
        }
    }

    Context "Rule exists" {
        Remove-NetFirewallRule -Name $test_rule_name -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName $test_rule_name -Name $test_rule_name -Protocol TCP -LocalPort $test_port

        It 'Detects if change is required' {
            Test-TargetResource -Name $test_rule_name -Port $test_port -Ensure "Present" | Should Be $true
            Test-TargetResource -Name $test_rule_name -Port ($test_port + 1) -Ensure "Present" | Should Be $false
            Test-TargetResource -Name $test_rule_name -Port $test_port -Ensure "Absent" | Should Be $false
        }

        It 'Removes the rule' {
            Set-TargetResource -Name $test_rule_name -Port $test_port -Ensure "Absent"
            Test-TargetResource -Name $test_rule_name -Port $test_port -Ensure "Absent" | Should Be $true
        }
    }
}
