# Hard-code Add for this run ----------- .\Manage-TeamOwners.ps1 -Mode Add
# Hard-code Remove for this run ----------- .\Manage-TeamOwners.ps1 -Mode Remove

param(
    # Optional: let you hard-code the action when running the script
    [ValidateSet("Add", "Remove")]
    [string]$Mode
)

# If Mode not supplied, ask interactively
if (-not $Mode) {
    $Mode = Read-Host "Do you want to Add or Remove teachers as Team Owners? (Add/Remove)"
}

# Normalise the input a bit
switch ($Mode.ToLower()) {
    'add'    { $Mode = 'Add' }
    'remove' { $Mode = 'Remove' }
    default {
        Write-Host "Invalid choice. Please run again and choose Add or Remove." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Mode selected: $Mode`n" -ForegroundColor Yellow

Connect-MicrosoftTeams

$TeamLists = Import-Csv "\\Path To CSV"

foreach ($team in $TeamLists) {
    $GroupId  = $team.GroupId
    $UserUPN  = "@domain.com"
    $TeamName = $team.Name
    $teacher  = $team.Owner + $UserUPN   # e.g. john.smith@domain.com

    if ($Mode -eq 'Add') {

        # ADD teacher as owner
        Write-Host "[$TeamName] Adding $teacher as an Owner to the Team..." -ForegroundColor Cyan
        try {
            Add-TeamUser -GroupId $GroupId -User $teacher -Role Owner
            Start-Sleep -Seconds 1
        }
        catch {
            Write-Host "[$TeamName] Failed to add $teacher as an Owner. Error: $_" -ForegroundColor Red
        }

    }
    elseif ($Mode -eq 'Remove') {

        # REMOVE teacher from team
        Write-Host "[$TeamName] Removing $teacher from the Team..." -ForegroundColor Magenta
        try {
            Remove-TeamUser -GroupId $GroupId -User $teacher
            Start-Sleep -Seconds 1
        }
        catch {
            Write-Host "[$TeamName] Failed to remove $teacher from the Team. Error: $_" -ForegroundColor Red
        }

    }
}
