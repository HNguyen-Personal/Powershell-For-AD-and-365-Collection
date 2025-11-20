##Connect Exchange
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

##Remove single Group using group ID, can use lots of things, refer to https://learn.microsoft.com/en-us/powershell/module/exchange/remove-unifiedgroup?view=exchange-ps
##Remove-UnifiedGroup -Identity "84047c27-c8bd-4e06-9e6e-cff423427521" -Confirm:$false

# Set CSV path
$csvPath = "\\Path\To\CSV"

# Import CSV
$groupList = Import-Csv -Path $csvPath

# Loop through each group ID and remove the group
foreach ($group in $groupList) {
    $groupId = $group.'Groups-Id'  # Adjust column name if needed
    if ($groupId) {
        Write-Host "Removing group: $groupId"
        try {
            Remove-UnifiedGroup -Identity $groupId -Confirm:$false
        }
        catch {
            Write-Warning "Failed to remove group $groupId : $_"
        }
    }
    else {
        Write-Warning "Skipped a row with empty Group ID."
    }
}
