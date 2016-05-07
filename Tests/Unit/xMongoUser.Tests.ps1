$resource_name = "xMongoUser"
$resource_path = $PSScriptRoot + "\..\..\DSCResources\${resource_name}"

if (Get-Module $resource_name) {
    Remove-Module $resource_name
}

Import-Module "${resource_path}\${resource_name}.psm1"

InModuleScope $resource_name {
    $test_username = "TestUser"
    $test_password = New-Object -TypeName System.Management.Automation.PSCredential `
            ("N/A", (ConvertTo-SecureString 'TestPassword' -AsPlainText -Force))
    $test_collection = "TestCollection"
    $test_mongopath = "M:\"

    $resource_name = $MyInvocation.MyCommand.ScriptBlock.Module.Name

    Describe "${resource_name}, Get-TargetResource" {

        Mock Invoke-MongoCommand { return "" }

        Get-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath

        It 'Calls Invoke-MongoCommand with expected arguments' {
            Assert-MockCalled Invoke-MongoCommand -ParameterFilter {
                ($Expression -eq "db.getUser('$test_username')") `
                -and ($Collection -eq $test_collection) `
                -and ($MongoPath -eq $test_mongopath) `
            }
        }

        Context 'User exists' {
            Mock Invoke-MongoCommand { return "[object Object]`n" }

            $returnValue = Get-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath

            It 'Returns Ensure = Present' {
                $returnValue.Ensure | Should BeExactly "Present"
            }
            It 'Returns UserPassword = null' {
                $returnValue.UserPassword | Should BeExactly $null
            }
        }
        Context "User doesn't exist" {
            Mock Invoke-MongoCommand { return "null`n" }

            $returnValue = Get-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath

            It 'Returns Ensure = Absent' {
                $returnValue.Ensure | Should BeExactly "Absent"
            }
        }
    }

    Describe "${resource_name}, Test-TargetResource" {
        Mock Get-TargetResource {}

        Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath

        It 'Calls Get-TargetResource with expected arguments' {
            Assert-MockCalled Get-TargetResource -ParameterFilter {
                ($UserName -eq $test_username) `
                -and ($Collection -eq $test_collection) `
                -and ($MongoPath -eq $test_mongopath)
            }
        }

        Context "User exists" {
            Mock Get-TargetResource { return @{
                Ensure = "Present"
            } }

            $returnValue = Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath

            It 'Returns true by default' {
                $returnValue | Should BeExactly $true
            }

            $returnValue = Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Present"

            It 'Returns true when Ensure = Present' {
                $returnValue | Should BeExactly $true
            }

            $returnValue = Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Absent"

            It 'Returns false when Ensure = Absent' {
                $returnValue | Should BeExactly $false
            }
        }
        Context "User doesn't exist" {
            Mock Get-TargetResource { return @{
                Ensure = "Absent"
            } }

            $returnValue = Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Absent"

            It 'Returns true when Ensure = Absent' {
                $returnValue | Should BeExactly $true
            }

            $returnValue = Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Present"

            It 'Returns false when Ensure = Present' {
                $returnValue | Should BeExactly $false
            }

            $returnValue = Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath

            It 'Returns false by default' {
                $returnValue | Should BeExactly $false
            }
        }
    }

    Describe "${resource_name}, Set-TargetResource" {
        Mock Invoke-MongoCommand {}

        Context "User exists" {
            Mock Get-TargetResource { return @{ Ensure = "Present" } }

            Set-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath

            It 'Does nothing when Ensure is not specified' {
                Assert-MockCalled Invoke-MongoCommand -Exactly -Times 0
            }
        }
        Context "User exists" {
            Mock Get-TargetResource { return @{ Ensure = "Present" } }

            Set-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Present"

            It 'Does nothing when Ensure = Present' {
                Assert-MockCalled Invoke-MongoCommand -Exactly -Times 0
            }
        }
        Context "User exists" {
            Mock Get-TargetResource { return @{ Ensure = "Present" } }

            Set-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Absent"

            It 'Removes user when Ensure = Absent' {
                Assert-MockCalled Invoke-MongoCommand -ParameterFilter {
                    ($Expression -eq "db.dropUser('$test_username')") `
                    -and ($Collection -eq $test_collection) `
                    -and ($MongoPath -eq $test_mongopath) `
                }
            }
        }
        Context "User doesn't exist" {
            Mock Get-TargetResource { return @{ Ensure = "Absent" } }

            Set-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath

            It 'Creates user when Ensure is not specified' {
                $password_string = $test_password.GetNetworkCredential().Password
                Assert-MockCalled Invoke-MongoCommand -ParameterFilter {
                    ($Expression -eq "db.createUser({ user:'$test_username', pwd:'$password_string', roles:[] })") `
                    -and ($Collection -eq $test_collection) `
                    -and ($MongoPath -eq $test_mongopath) `
                }
            }
        }
        Context "User doesn't exist" {
            Mock Get-TargetResource { return @{ Ensure = "Absent" } }

            Set-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Present"

            It 'Creates user when Ensure = Present' {
                $password_string = $test_password.GetNetworkCredential().Password
                Assert-MockCalled Invoke-MongoCommand -ParameterFilter {
                    ($Expression -eq "db.createUser({ user:'$test_username', pwd:'$password_string', roles:[] })") `
                    -and ($Collection -eq $test_collection) `
                    -and ($MongoPath -eq $test_mongopath) `
                }
            }
        }
        Context "User doesn't exist" {
            Mock Get-TargetResource { return @{ Ensure = "Absent" } }

            Set-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Absent"

            It 'Does nothing when Ensure = Absent' {
                Assert-MockCalled Invoke-MongoCommand -Exactly -Times 0
            }
        }
    }
}
