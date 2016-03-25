$this_script_path = Split-Path -Parent $MyInvocation.MyCommand.Path

$resource_name = "xMongoUser"
$resource_path = Join-Path -Path $((Get-Item $this_script_path).Parent.FullName) -ChildPath "DSCResources\${resource_name}"

if (! (Get-Module xDSCResourceDesigner)) {
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

if (Get-Module $resource_name) {
    Remove-Module $resource_name
}

Import-Module "${resource_path}\${resource_name}.psm1"

Describe "${resource_name}, Integration Tests" {
    $test_username = "TestUser"
    $test_password = New-Object -TypeName System.Management.Automation.PSCredential `
            ("N/A", (ConvertTo-SecureString 'TestPassword' -AsPlainText -Force))
    $test_collection = "TestCollection"
    $test_mongopath = "C:\MongoDB"

    function New-TestUser {
        $password_string = $test_password.GetNetworkCredential().Password
        & "$test_mongopath\bin\mongo.exe" --eval "db.createUser({ user:'$test_username', pwd:'$password_string', roles:[] })" $test_collection
    }

    function Remove-TestUser {
        & "$test_mongopath\bin\mongo.exe" --eval "db.dropUser('$test_username')" $test_collection
    }

    Context "User doesn't exist" {
        Remove-TestUser

        It 'Gets the correct result' {
            $result = Get-TargetResource  -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath
            $result.Ensure | Should Be "Absent"
        }

        It 'Detects if change is required' {
            Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Present" | Should Be $false
            Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Absent" | Should Be $true
        }

        It 'Creates the User' {
            Set-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath
            Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Present" | Should Be $true
            Remove-TestUser
        }
    }

    Context "User exists" {
        Remove-TestUser
        New-TestUser

        It 'Gets the correct result' {
            $result = Get-TargetResource  -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath
            $result.Ensure | Should Be "Present"
        }

        It 'Detects if change is required' {
            Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Present" | Should Be $true
            Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Absent" | Should Be $false
        }

        It 'Removes the User' {
            Set-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Absent"
            Test-TargetResource -UserName $test_username -UserPassword $test_password -Collection $test_collection -MongoPath $test_mongopath -Ensure "Absent" | Should Be $true
        }
    }
}
