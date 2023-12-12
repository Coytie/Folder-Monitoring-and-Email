# Import necessary modules
Import-Module Microsoft.PowerShell.SecretManagement
Import-Module Microsoft.PowerShell.SecretStore

# In this section, we're going to use C:\scripts folder but you can set it to anywhere you want
$nfp = "C:\Scripts\Script Data" # New Folder Path where we are going to save the temp files before deleting
$abpath = "C:\Path\to\Folder","D:\Path\to\Folder","E:\Path\to\Folder" # Main locations you want to check
$obpath = "D:\Path\to\Excluded\Folder","E:\Path\to\Excluded\Folder" # Adding the excluded folder path
$abdata = $nfp + "\pickaname.csv" # abpath data save location
$obdata = $nfp + "\pickanothername.csv" # obpath data save location
$totaldata = $nfp + "\totalofbothnames.csv" # Total Combined Data of obdata and abdata

# Email Variables
$User = "ad.username@yourdomain.com.au"
$Pass = Get-Secret -Name SASecret
$EmailCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass

# Function to get the "abdata" data
function Get-ABDataFolder {
    $path = $abpath
    $folders = Get-ChildItem -Path $Path -Directory
    
# Get Folder Size
$FolderSizes = foreach ($folder in $folders) {
    $size = (Get-ChildItem -Path $folder.FullName -File -Recurse -exclude "folder name you're exclusing" | Measure-Object -Property Length -Sum).Sum
    $sizeInTB = $size / 1TB

    [PSCustomObject]@{
        FolderName = $folder.Name
        SizeInTB = [Math]::Round($sizeInTB,2)
    }
}

$EmailFolderSize = $FolderSizes | where-object{$_.FolderName -notlike "folder name you're exclusing"} | Group-Object FolderName | ForEach-Object{
    [PSCustomObject]@{
    Company = ($_.Group.Foldername)
    SizeInTB  = ($_.Group.SizeInTB | Measure-Object -sum).Sum
    }
} | Format-Table | Out-String | Out-File $abdata
}

# Function to get the "obdata" data
function Get-OBDataFolder {
    $path = $obpath
    $folders = Get-ChildItem -Path $Path -Directory
    
# Get Folder Size
$FolderSizes = foreach ($folder in $folders) {
    $size = (Get-ChildItem -Path $folder.FullName -File -Recurse | Measure-Object -Property Length -Sum).Sum
    $sizeInTB = $size / 1TB

    [PSCustomObject]@{
        FolderName = $folder.Name
        SizeInTB = [Math]::Round($sizeInTB,2)
    }
}

$EmailFolderSize = $FolderSizes | where-object{$_.FolderName -notlike "folder name you're exclusing"} | Group-Object FolderName | ForEach-Object{
    [PSCustomObject]@{
    Company = ($_.Group.Foldername)
    SizeInTB  = ($_.Group.SizeInTB | Measure-Object -sum).Sum
    }
} | Format-Table | Out-String | Out-File $obdata
}

# Function to get the total backup data
function Get-TotalDataFolder {
$path = $abpath + $obpath
$folders = Get-ChildItem -Path $Path -Directory

# Get Folder Size
$FolderSizes = foreach ($folder in $folders) {
    $size = (Get-ChildItem -Path $folder.FullName -File -Recurse | Measure-Object -Property Length -Sum).Sum
    $sizeInTB = $size / 1TB

    [PSCustomObject]@{
        FolderName = $folder.Name
        SizeInTB = [Math]::Round($sizeInTB,2)
    }
}

$EmailFolderSize = $FolderSizes | where-object{$_.FolderName -notlike "folder name you're exclusing"} | Group-Object FolderName | ForEach-Object{
    [PSCustomObject]@{
    Company = ($_.Group.Foldername[0])
    SizeInTB  = ($_.Group.SizeInTB | Measure-Object -sum).Sum
    }
} | Format-Table | Out-String | Out-File $totaldata
}

try {
New-Item -ItemType Directory -Path $nfp

Get-ABDataFolder
Get-OBDataFolder
Get-TotalDataFolder

$abbody = Get-Content -Path $abdata | Out-String
$obbody = Get-Content -Path $obdata | Out-String
$totalbody = Get-Content -Path $totaldata | Out-String

# Sending Email Message
$Message = @{
    SmtpServer = 'your.smtpserver.com.au'
    Port = '587'
    To = 'Users Name <username@yourdomainname.com.au>'
    From = 'SMTP User <username@uourdomainname.com.au>'
    Subject = 'Subject Name Here'
    Body = "Add some info here." + "`n`nThe data below is from the First Drive:" + $abbody + "The data below is from the second drive:" + $obbody + "The data below is the total of both drives:" + $totalbody
    DeliveryNotificationOption = "OnSuccess, OnFailure"
    credential = $EmailCredential
}

Send-MailMessage @Message

Start-Sleep -Seconds 10
Remove-Item -Path $nfp -Force -Recurse
}

catch {
    # Handle errors
    write-error "Error: $_"
    # you can log or display additional information about the error here
}
