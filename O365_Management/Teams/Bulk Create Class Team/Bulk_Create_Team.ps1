#Parameters
$CSVFile = "\\Path\to\CSV\File"
$outputCSVFile = "C\\Path\to\CSV\File"

# Array to store output data
$ExportData = @()

Try {
    # Read the CSV File
    $TeamsData = Import-CSV -Path $CSVFile

    # Connect to Microsoft Teams
    Import-Module -Name MicrosoftTeams

    # Parameters for Credentials --- Hard coded, only use privately for quick action
    $UserName = "admin@johndoe.com"
    $PassWord = ConvertTo-SecureString -String "VeryStrongPassword" -AsPlainText -Force

    # Create a Credential object
    $Cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $UserName, $PassWord

    # Connect to Microsoft Teams
    #Connect-MicrosoftTeams
    Connect-MicrosoftTeams -Credential $Cred

    # Iterate through the CSV
    ForEach($Team in $TeamsData) {
        Try {
            # Create a New Team
            Write-host -f Yellow "Creating Team:" $Team.TeamName
            $NewTeam = New-Team -DisplayName $Team.TeamName -Description $Team.Description -MailNickName $Team.MailNickName -Template EDU_Class -ErrorAction Stop #-Visibility $Team.Visibility
            Write-host "\tNew Team '$($Team.TeamName)' Created Successfully" -f Green

            # Add the Team details to the ExportData array
            $ExportData += [PSCustomObject]@{
                TeamName    = $Team.TeamName
                GroupId     = $NewTeam.GroupId
                SubjectCode = $Team.SubjectCode
            }

        } Catch {
            Write-host -f Red "Error Creating Team:" $_.Exception.Message
        }
    }

    # Ensure the directory for the output file exists
    $outputDirectory = Split-Path -Path $outputCSVFile -Parent
    If (!(Test-Path -Path $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    # Check if the output CSV file exists and import existing data if present
    If (Test-Path -Path $outputCSVFile) {
        $ExistingData = Import-Csv -Path $outputCSVFile
        $ExportData += $ExistingData
    }

    # Export the collected data to CSV
    $ExportData | Export-Csv -Path $outputCSVFile -NoTypeInformation -Encoding UTF8
    Write-Host "Teams creation details exported successfully to $outputCSVFile" -f Green

} Catch {
    Write-host -f Red "Error:" $_.Exception.Message
}
