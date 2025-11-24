Set-ExecutionPolicy Bypass 

Install-Module -Name PowerShellGet -Force -AllowClobber

Install-Module -Name MicrosoftTeams -Force -AllowClobber

Import-Module MicrosoftTeams

## Manually Connect to MS Teams
# Connect-MicrosoftTeams


##Hard Coded for quick access
$UserName = "JohnDoe@domain.com"
$PassWord = ConvertTo-SecureString -String "VeryStrongPassword" -AsPlainText -Force

#Create a Credential object
$Cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $UserName, $PassWord

# Connect to Microsoft Teams
Connect-MicrosoftTeams -Credential $Cred

## Single Group Archive
#Set-TeamArchivedState -GroupId 105b16e2-dc55-4f37-a922-97551e9e862d -Archived:$true -SetSpoSiteReadOnlyForMembers:$true

$ArchiveGroups = Import-CSV "\\Path\to\csv"

Foreach ($Group in $ArchiveGroups) {
    Set-TeamArchivedState -GroupId $Group.ExternalDirectoryObjectId -Archived:$true -SetSpoSiteReadOnlyForMembers:$true
}