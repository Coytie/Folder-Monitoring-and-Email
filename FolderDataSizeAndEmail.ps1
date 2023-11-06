#This command is on the assumption that you are using the SecretManagement and SecretStore powershell modules to manage passwords. Can use any other credential manager but need to change credentials section.

Import-module Microsoft.PowerShell.SecretManagement
Import-Module Microsoft.PowerShell.SecretStore

#Folder Veriables
$path = "C:\FolderPathHere", #You can add multiple locations by adding , " " after each one.
$dataTempPath = 'C:\Your\Save\Location\outputfile.txt' #This is where the output data will save temporarily.
$folders = Get-ChildItem -Path $Path -Directory

#Email Veriables
$User = "username@domain.com"
$Pass = Get-Secret -Name "YourSecretNameHere" #This is where your password is kept in the SecretManagement Vault
$EmailCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass

#Get Folder Size
$FolderSizes = foreach ($folder in $folders) {
    $size = (Get-ChildItem -Path $folder.FullName -File -Recurse | Measure-Object -Property Length -Sum).Sum
    $sizeInTB = $size / 1TB

    [PSCustomObject]@{
        FolderName = $folder.Name
        SizeInTB = [Math]::Round($sizeInTB,2)
    }
}

$EmailFolderSize = $FolderSizes <#| where-object{$_.FolderName -notlike "test folder"}#> | Group-Object FolderName | ForEach-Object{ #remove the <# #> from earlier if you want to t filter out a folder.
    [PSCustomObject]@{
    Company = ($_.Group.Foldername[0])
    SizeInTB  = ($_.Group.SizeInTB | Measure-Object -sum).Sum
    }
} | Format-Table | Out-String | Out-File $dataTempPath

$body = get-content -Path $dataTempPath | Out-String

#Sending Email Message
$Message = @{ SmtpServer = 'smtp server'
              Port = '587'
              To = 'Users Name <username@domain.com>'
              From = 'Users Name <username@domain.com>'
              Subject = 'Subject of the email'
              Body = 'You can put a text before the file output here, otherwise remove remove everything except $body' + $body
              DeliveryNotificationOption = "OnSuccess, OnFailure"
              credential = $EmailCredential
            }

Send-MailMessage @Message
Start-Sleep -seconds 10 #this is just to give enough time for the email to be received in the smtp server, not really nessessary.
Remove-Item -path $dataTempPath
