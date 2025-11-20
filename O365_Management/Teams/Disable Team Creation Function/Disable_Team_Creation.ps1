## Source: https://www.edugeek.net/forums/topic/218682-disable-teams-group-creation-with-exception-groupcreationallowedgroupid/

## ------------- Just search for the Group ID directly in admin console----------------##########

Import-Module Microsoft.Graph.Beta.Identity.DirectoryManagement
Import-Module Microsoft.Graph.Beta.Groups

Connect-MgGraph -Scopes "Directory.ReadWrite.All", "Group.Read.All"

##$GroupName = "Teams Creators" ----- This is the bit we're bypassing :D
$AllowGroupCreation = "False"
$settingsObjectID = (Get-MgBetaDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
if(!$settingsObjectID)
{
$params = @{
templateId = "62375ab9-6b52-47ed-826b-58e47e0e304b"
values = @(
@{
name = "EnableMSStandardBlockedWords"
value = "true"
}
)
}
New-MgBetaDirectorySetting -BodyParameter $params
$settingsObjectID = (Get-MgBetaDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).Id
}

##$groupId = (Get-MgBetaGroup | Where-object {$_.displayname -eq $GroupName}).Id ---- This is the search / filter function that doesn't work!!

$params = @{
templateId = "62375ab9-6b52-47ed-826b-58e47e0e304b"
values = @(
@{
name = "EnableGroupCreation"
value = $AllowGroupCreation
}
@{
name = "GroupCreationAllowedGroupId"
value = "090e1991-01be-423f-8782-d4c5c704dfc3" ##Rather than search for security ID, Just provide it, it's easy enough to find in Azure.
}
)
}
Update-MgBetaDirectorySetting -DirectorySettingId $settingsObjectID -BodyParameter $params
(Get-MgBetaDirectorySetting -DirectorySettingId $settingsObjectID).Values