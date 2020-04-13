<#

PowerShell Lab 7
Creating and removing users, OU's, groups, and group membership
Date: Apr 9, 2020
Created by: Tyler Zahuranec

#>

cls

$menu = @"
Choose from the following Menu Items:
    A. View one OU         B. View all OUs
    C. View one group      D. View all groups
    E. View one user       F. View all users


    G. Create one OU       H. Create one group
    I. Create one user     J. Create users from CSV file


    K. Add user to group   L. Remove user from group


    M. Delete one group    N. Delete one user


ENTER 'Q' TO QUIT

"@
 

do {
$menu
$choice = Read-Host "What option do you want to do? "

    if ($choice -eq "A") {
        $OUname = Read-Host "What is the name of the OU? "
        Get-ADOrganizationalUnit -Identity "OU=$OUname, DC=Adatum, DC=Com" -Properties Name, DistinguishedName | Format-Table
        pause
    }
    elseif ($choice -eq "B") {
        Get-ADOrganizationalUnit -Filter * -Properties Name, DistinguishedName | Format-Table
        pause
    } 
    elseif ($choice -eq "C") {
        $groupname = Read-Host "What group would you like to view? "
        Get-ADGroup -Identity "$groupname" -Properties Name, GroupScope, GroupCategory | Format-Table
        pause
    } 
    elseif ($choice -eq "D") {
        Get-ADGroup -Filter * -Properties Name, GroupScope, GroupCategory | Format-Table
        pause
    } 
    elseif ($choice -eq "E") {
        $user = Read-Host "What is the name of the user? "
        Get-ADUser -Identity "$user" -Properties Name, DistinguishedName | Format-Table
        pause
    } 
    elseif ($choice -eq "F") {
        Get-ADUser -Filter * -Properties Name, DistinguishedName, Name, SurName | Format-Table
        pause
    } 
    elseif ($choice -eq "G") {
        $OUcreate = Read-Host "What is the name of the OU you want to create? "
        New-ADOrganizationalUnit -Name $OUcreate -ProtectedFromAccidentalDeletion $false
        Get-ADOrganizationalUnit -Identity "OU=$OUcreate, DC=Adatum, DC=Com" -Properties Name, DistinguishedName | Format-Table
        pause
    } 
    elseif ($choice -eq "H") {
        $groupCreate = Read-Host "What is the name of the group you want to create? "
        New-ADGroup -Name $groupCreate -GroupScope Global -GroupCategory Security 
        Get-ADGroup -Identity "$groupCreate" -Properties Name, GroupScope, GroupCategory | Format-Table
        pause
    } 
    elseif ($choice -eq "I") {
        $userCreate = Read-Host "What is the name of the user you want to create? "
        $userFname = Read-Host "What is the user's first name? "
        $userLname = Read-Host "What is the user's last name? "
        $userStreet = Read-Host "What is the user's street address? "
        $userCity = Read-Host "What is the user's city? "
        $userState = Read-Host "What is the user's state? "
        $userZip = Read-Host "What is the user's zip code? "
        $userCompany = Read-Host "What is the user's company? "
        $userDivision = Read-Host "What is the user's division? "
        $userPassword = ConvertTo-SecureString -String "Password01" -AsPlainText -Force

        $userParams = @{ Name = $userCreate;
                         SamAccountName = $userCreate;
                         UserPrincipalName = "$userCreate@adatum.com";
                         GivenName = $userFname;
                         Surname = $userLname;
                         Enabled = $true
                         City = $userCity;
                         State = $userState;
                         StreetAddress = $userStreet;
                         Company = $userCompany;
                         Division = $userDivision;
                         PostalCode = $userZip

        }

        $userLocation = Read-Host "Are you adding $userCreate to the users container or to an OU?`nIf to users, type 'users', if to OU, type 'OU'`n`n"
            #If statement for the choice between users container or OU
            if ($userLocation -eq "users") {
                New-ADUser @userParams -AccountPassword $userPassword -Path "CN=users, DC=adatum, DC=com"
                Get-ADUser -Identity "CN=$userCreate, CN=users, DC=adatum, DC=com" -Properties Name, SamAccountName, UserPrincipalName, Name, SurName, City, State, PostalCode, Company, Division | Format-List
            }
            elseif ($userLocation -eq "OU") {
                Write-Output "The OU must be an existing one to avoid error!`n"
                #Another Do Until loop to check if the OU exists before trying to add a user to it
                do {
                    $OUname = Read-Host "Enter the name of the OU?`nYou can also enter 'Q' to cancel "
                    $pathTest = [adsi]::Exists("LDAP://OU=$OUname,DC=adatum,DC=com")

                    if ($pathTest -eq $true) {
                        New-ADUser @userParams -AccountPassword $userPassword -Path "OU=$OUname, DC=adatum, DC=com"
                        Get-ADUser -Identity "CN=$userCreate, OU=$OUname, DC=adatum, DC=com" -Properties Name, SamAccountName, UserPrincipalName, Name, SurName, City, State, PostalCode, Company, Division | Format-List
                    }
                    else {
                        Write-Output "The OU name you entered does not exist!`n`n"
                        pause
                    }
                } until ($pathTest -eq $true -or $OUname -eq "Q") #here I give the option to end the loop if they enter "Q" or if the OU exists
            }
            #For when someone enters something other than "users" or "OU"
            else {
                Write-Output "Not a valid entry! "
            }
            pause
        } 
    elseif ($choice -eq "J") {
        $userFile = Read-Host "What is the name of the file? "
        $userPass = Read-Host "What is the password the users will have? "
        $securePass = ConvertTo-SecureString -String $userPass -AsPlainText -Force
        $FileImport = Import-Csv -Path $env:USERPROFILE\$userfile.csv
        $FileImport | New-ADUser -AccountPassword $securePass -Enabled $true
        Write-Output "Importing the new users!"
        pause
        Get-ADUser -Filter * -Properties Name, SamAccountName, UserPrincipalName, GivenName, Surname, City, State, PostalCode, Company, Division | Format-List
        
        pause
    } 
    elseif ($choice -eq "K") {
        $groupAddUser = Read-Host "What is the name of the group that you want to add a user to? "
        $userToGroup = Read-Host "What is the name of the user moving to $groupAddUser`? "
        Add-ADGroupMember -Identity "CN=$groupAddUser, CN=Users, DC=Adatum, DC=Com" -Members "CN=$userToGroup, CN=Users, DC=Adatum, DC=Com"
        Get-ADUser -Identity "CN=$userToGroup, CN=Users, DC=Adatum, DC=Com" -Properties SamAccountName, DistinguishedName, MemberOf | Format-Table
        
        pause
    } 
    elseif ($choice -eq "L") {
        $RemoveUserFromGroup = Read-Host "What is the name of the group that will lose a member? "
        Get-ADGroup -Identity $RemoveUserFromGroup -Properties Members| Format-Table
        $confirmRemove = Read-Host "Do you want to remove a user from this group?`n`nType 'Y' for Yes and 'N' for No"
            if ($confirmRemove -eq "Y") {
                $userName = Read-Host "What is the name of the user you want to remove? "
                Remove-ADGroupMember -Identity $RemoveUserFromGroup -Members $userName
                Get-ADGroup -Identity $RemoveUserFromGroup -Properties Members
            }
            else {
                Write-Output "Canceling"
            }
        pause
    } 
    elseif ($choice -eq "M") {
        $groupdelete = Read-Host "What is the name of the group you want to delete? "
        Remove-ADGroup -Identity "CN=$groupdelete, CN=users, DC=adatum, DC=com"
        Get-ADGroup -Filter * -Properties Name, GroupScope, GroupCategory | Format-Table
        pause
    } 
    elseif ($choice -eq "N") {
        $userDelete = Read-Host "What is the name of the user you want to delete? "
        Remove-ADUser -Identity "CN=$userDelete, CN=users, DC=adatum, DC=com"
        Get-ADUser -Filter * -Properties Name, DistinguishedName | Format-Table
        pause
    } 
    elseif ($choice -eq "Q") {
        Write-Output "`nThank You for using this program!"
    } 
    else {
        Write-Output "You did not make a valid choice" 
        pause
    }
   

} until ($choice -eq "Q")


