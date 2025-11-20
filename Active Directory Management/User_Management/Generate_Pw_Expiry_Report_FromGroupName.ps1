##Intended to work for fine-grain password policy, not default policy

# Import Active Directory Module
Import-Module ActiveDirectory

# Prompt for Group Name
$groupName = "Group_XXXX"

# Get Group Members
Write-Output "Retrieving members of group: $groupName"
$groupMembers = Get-ADGroupMember -Identity $groupName -Recursive | Where-Object { $_.objectClass -eq "user" }

# Check if group members were found
if (-not $groupMembers) {
    Write-Output "No members found in group: $groupName"
    Exit
}

# Initialize an array to hold user data
$userData = @()

# Process each user
foreach ($member in $groupMembers) {
    try {
        $user = Get-ADUser -Identity $member.SamAccountName -Properties DisplayName, PasswordLastSet, EmailAddress, PasswordNeverExpires, Enabled, msDS-ResultantPSO

        # Skip users with PasswordNeverExpires set to true
        if ($user.PasswordNeverExpires -eq $true) {
            continue
        }

        # Determine applicable password policy
        $policy = if ($user.'msDS-ResultantPSO') {
            Get-ADFineGrainedPasswordPolicy -Identity $user.'msDS-ResultantPSO'
        } else {
            Get-ADDefaultDomainPasswordPolicy
        }

        $maxPasswordAge = $policy.MaxPasswordAge.Days

        # Calculate password expiry date
        $passwordExpiryDate = $user.PasswordLastSet.AddDays($maxPasswordAge)

        # Determine user status
        $status = if ($user.Enabled) { "Active" } else { "Disabled" }

        # Create a custom object to store user data
        $userInfo = [PSCustomObject]@{
            DisplayName         = $user.DisplayName
            SamAccountName      = $user.SamAccountName
            EmailAddress        = $user.EmailAddress
            PasswordLastSet     = $user.PasswordLastSet
            PasswordExpiryDate  = $passwordExpiryDate
            DaysUntilExpiry     = ($passwordExpiryDate - (Get-Date)).Days
            MaxPasswordAge      = $maxPasswordAge
            AccountStatus       = $status
        }

        $userData += $userInfo
    } catch {
        Write-Output "Error processing user: $($member.SamAccountName)"
    }
}

# Check if any user data was collected
if (-not $userData) {
    Write-Output "No valid user data found for group: $groupName"
    Exit
}

# Export the data to CSV
$outputPath = "C:\${groupName}_PasswordExpiryReport.csv"
$userData | Sort-Object DaysUntilExpiry | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

Write-Output "Password expiry report exported to: $outputPath"
