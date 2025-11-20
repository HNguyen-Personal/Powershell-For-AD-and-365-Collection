
Set-ExecutionPolicy Bypass 

Install-Module -Name PowerShellGet -Force -AllowClobber

Install-Module -Name MicrosoftTeams -Force -AllowClobber

Import-Module MicrosoftTeams

# Prompt for Microsoft 365 credentials
$UserCredential = Get-Credential

# Connect to Microsoft Teams
Connect-MicrosoftTeams -Credential $UserCredential

# Import the CSV file with GroupIDs
$csvPath = "C:\List3.csv"
$groupIds = Import-Csv -Path $csvPath

# Loop through each GroupId and unarchive the team
foreach ($group in $groupIds) {
    $groupId = $group.GroupId
    try {
        # Unarchive the team
        Set-TeamArchivedState -GroupId $groupId -Archived:$false
        Write-Host "Successfully unarchived Team with GroupId: $groupId"
    } catch {
        Write-Host "Failed to unarchive Team with GroupId: $groupId - Error: $_"
    }
}