Import-Module ActiveDirectory

$baseOU = "OU=xx,OU=xx,DC=xx,DC=xx,DC=xx,DC=xx"

# Load all FGPPs with targets
$fgpps = Get-ADFineGrainedPasswordPolicy -Filter * | ForEach-Object {
    $pso = $_
    $targets = ($pso | Get-ADFineGrainedPasswordPolicySubject).DistinguishedName
    [PSCustomObject]@{
        Name = $pso.Name
        MaxPasswordAge = $pso.MaxPasswordAge
        Targets = $targets
    }
}

# Get all users
$users = Get-ADUser -SearchBase $baseOU -Filter * -Properties pwdLastSet, accountExpires, DistinguishedName, MemberOf

$results = foreach ($user in $users) {
    # Convert pwdLastSet
    $pwdLastSet = if ($user.pwdLastSet -ne 0) {
        [datetime]::FromFileTime($user.pwdLastSet)
    } else {
        $null
    }

    # Convert accountExpires
    $accountExpires = if ($user.accountExpires -ne 0 -and $user.accountExpires -ne 9223372036854775807) {
        [datetime]::FromFileTime($user.accountExpires)
    } else {
        "Never"
    }

    # Get group DNs
    $userGroups = @()
    try {
        $userGroups = (Get-ADUser $user.SamAccountName -Properties MemberOf).MemberOf
    } catch {}

    # Match FGPP
    $matchedPolicy = $null
    foreach ($fgpp in $fgpps) {
        if ($fgpp.Targets -contains $user.DistinguishedName) {
            $matchedPolicy = $fgpp
            break
        } elseif ($userGroups | Where-Object { $fgpp.Targets -contains $_ }) {
            $matchedPolicy = $fgpp
            break
        }
    }

    # Policy info
    $policyName = if ($matchedPolicy) { $matchedPolicy.Name } else { "No FGPP - Domain Default" }
    $maxPasswordAge = if ($matchedPolicy) { $matchedPolicy.MaxPasswordAge } else { (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge }

    # Password expiry
    $pwdExpiryDate = if ($pwdLastSet -and $maxPasswordAge) {
        $pwdLastSet + $maxPasswordAge
    } else {
        "Unknown"
    }

    # Sub-OU extraction
    $dnParts = $user.DistinguishedName -split ","
    $subOUs = @()
    foreach ($part in $dnParts) {
        if ($part -like "OU=Students") { break }
        if ($part -like "OU=*") {
            $subOUs += $part -replace "OU=", ""
        }
    }
    $subOU = if ($subOUs.Count -gt 0) { ($subOUs -join "/") } else { "Root" }

    # Final output
    [PSCustomObject]@{
        SamAccountName     = $user.SamAccountName
        Name               = $user.Name
        SubOU              = $subOU
        PwdLastSet         = if ($pwdLastSet) { $pwdLastSet } else { "Never" }
        PolicyName         = $policyName
        MaxPasswordAge     = $maxPasswordAge.Days.ToString() + " days"
        PasswordExpiryDate = $pwdExpiryDate
        AccountExpires     = $accountExpires
    }
}

# Export
$results | Export-Csv -Path "C:\StudentUsers_PasswordExpiry_Full.csv" -NoTypeInformation -Encoding UTF8
Write-Output "✅ Exported to C:\StudentUsers_PasswordExpiry_Full.csv"
