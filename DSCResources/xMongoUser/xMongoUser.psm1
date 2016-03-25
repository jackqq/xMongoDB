function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [String] $UserName,

        [parameter(Mandatory = $true)]
        [PSCredential] $UserPassword,

        [parameter(Mandatory = $true)]
        [String] $Collection,

        [parameter(Mandatory = $true)]
        [String] $MongoPath
    )

    $result = Invoke-MongoCommand -MongoPath $MongoPath -Expression "db.getUser('$UserName')" -Collection $Collection
    $result = $result.Trim()

    if ($result -ne "null") {
        Write-Verbose "User exists."
        $ensureResult = "Present"
    } else {
        Write-Verbose "User does not exist."
        $ensureResult = "Absent"
    }

    return @{
        UserName = $UserName
        UserPassword = $null
        Collection = $Collection
        MongoPath = $MongoPath
        Ensure = $ensureResult
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [String] $UserName,

        [parameter(Mandatory = $true)]
        [PSCredential] $UserPassword,

        [parameter(Mandatory = $true)]
        [String] $Collection,

        [parameter(Mandatory = $true)]
        [String] $MongoPath,

        [ValidateSet("Present","Absent")]
        [String] $Ensure = "Present"
    )

    $result = Get-TargetResource -UserName $UserName -UserPassword $UserPassword -Collection $Collection -MongoPath $MongoPath

    if ($result.Ensure -eq "Present") {
        if ($Ensure -eq "Present") {
            Write-Verbose "Nothing to do."
        } else {
            Write-Verbose "Remove user."
            Invoke-MongoCommand -MongoPath $MongoPath -Expression "db.dropUser('$UserName')" -Collection $Collection
        }
    } else {
        if ($Ensure -eq "Present") {
            Write-Verbose "Create user."
            $password_string = $UserPassword.GetNetworkCredential().Password
            Invoke-MongoCommand -MongoPath $MongoPath -Expression "db.createUser({ user:'$UserName', pwd:'$password_string', roles:[] })" -Collection $Collection
        } else {
            Write-Verbose "Nothing to do."
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
        [String] $UserName,

        [parameter(Mandatory = $true)]
        [PSCredential] $UserPassword,

        [parameter(Mandatory = $true)]
        [String] $Collection,

        [parameter(Mandatory = $true)]
        [String] $MongoPath,

        [ValidateSet("Present","Absent")]
        [String] $Ensure = "Present"
    )

    $result = Get-TargetResource -UserName $UserName -UserPassword $UserPassword -Collection $Collection -MongoPath $MongoPath

    if ($result.Ensure -eq $Ensure) {
        if ($Ensure -eq "Present") {
            Write-Verbose "User exists and is expected so."
            return $true
        } else {
            Write-Verbose "User doesn't exist and is expected not."
            return $true
        }
    } else {
        Write-Verbose "User's existence is not as expected."
        return $false
    }
}


function Invoke-MongoCommand
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [String] $MongoPath,

        [parameter(Mandatory = $true)]
        [String] $Expression,

        [String] $Collection
    )

    & "${MongoPath}\bin\mongo.exe" --quiet --eval $Expression $Collection
}


Export-ModuleMember -Function *-TargetResource

