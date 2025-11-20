# Gets the current date
$date=Get-Date -Format "yyyyMMdd"

# Creates a folder under C:\Temp with the current date where the files will be stored
mkdir "c:\temp\$date" -force

# Gets a list of all OU's under **
$ous = Get-ADOrganizationalUnit -Filter * -SearchBase 'OU=Users,OU=School,DC=curriculum,DC=regency-park-ps,DC=edu,DC=vic,DC=gov,DC=au' -SearchScope OneLevel

# Will retrieve all user accounts for every OU found under ** and export it to C:\Temp
foreach($ou in $ous)
{
    $csv = $ou.name + ".csv"

    Get-ADUser -Filter * -SearchBase $ou.DistinguishedName -Properties "SamAccountName","cn", "mail", "Office", "LastLogonDate", "PasswordLastSet" | 
    Select-Object @{Name="Username";Expression={$_.SamAccountName}}, @{Name="Full Name";Expression={$_.cn}}, @{Name="E-mail";Expression={$_.mail}}, @{Name="Mailbox Type";Expression={$_.MsExchRecipientTypeDetails}}, @{Name="Last Logon Date";Expression={$_.lastlogondate}}, @{Name="Location";Expression={$_.Office}}, passwordlastset, enabled |
        Export-csv C:\Temp\$date\$csv -NoTypeInformation
}
