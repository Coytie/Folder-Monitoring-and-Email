# Import necessary modules
Import-Module Microsoft.PowerShell.SecretManagement
Import-Module Microsoft.PowerShell.SecretStore

# Veriables for the script - Add more if required
$nfp = "C:\Scripts\Script Data"   # New Folder Path
$abdpath = "D:\Foldername"   # Folder Path - D Drive
$abepath = "E:\Foldername"   # Folder Path - E Drive
$obdata = "E:\Foldername\Temp Folder"   # Another Folder Path - E Drive
$abddata = $nfp + "\DDriveFolderSize.csv"   # Folder Data - D Drive
$abedata = $nfp + "\EDriveFolderSize.csv"   # Folder Data - E Drive
$obdata = $nfp + "\EDriveFolderSize2.csv"   # Another Folder Data - E Drive
$totalpath = $($abdpath, $abepath) + $obpath   # Total Folder Data Path - This will have issues if you have more than 2, so you will need to add 2 in the bracket and + another like shown here.
$totaldata = $nfp + "\TotalFolderData.csv"   # Total Combined Data of obdata and abdata

$excludedfolder = "Temp Folder"   # Excluded Folder for the Function

# Email Variables
$User = "username@yourFQDN.com.au"
$Pass = Get-Secret -Name SASecret
$EmailCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass

# Email Message Infomation
$Message = @{
    SmtpServer = 'smtp.domain.com.au'
    Port = '587'
    To = "To Username <to.username@noneofyourbusiness.com.au>"
    From = "From Username <from.username@noneofyourbusiness.com.au>"
    Subject = 'Email Subject Change Me!'
    #body = '' This has been moved into the Try block on Line 139.
    DeliveryNotificationOption = "OnSuccess, OnFailure"
    credential = $EmailCredential
}

<#
.SYNOPSIS
    This function retrieves information about the size of folders within a specified path, excluding certain folders.

.DESCRIPTION
    The Get-FolderDataSize function calculates the size of each subfolder within the specified path, excluding the specified folder.
    The result is saved to an output file.

.PARAMETER Path
    Specifies the path of the parent folder.

.PARAMETER ExcludedPath
    Specifies the folder to be excluded from the calculation.

.PARAMETER OutputPath
    Specifies the path of the output file.

.PARAMETER MultipleInput
    $True value only. Use this if there are multiple folders with the same name but the count is not merging the names correctly or showing up with the first initial.
    ~Example~
    Company   Size
    -------   ----
          A   0.02

.EXAMPLE
    Get-FolderDataSize -Path "C:\YourFolderPath" -ExcludedPath "Temp Folder" -OutputPath "C:\YourOutputPath"

    Description
    -----------
    This example calculates the size of each subfolder within "C:\YourFolderPath" excluding "Temp Folder".
    The result is saved to "C:\YourOutputPath".

.NOTES
    File: FolderDataSize.ps1
    Author: Brenden Coyte
#>

function Get-FolderDataSize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ValueFromRemainingArguments=$true)]
        [string[]]$Path,

        [Parameter(Mandatory=$false)]
        [string]$ExcludedPath,

        [Parameter(Mandatory=$false)]
        [string]$OutputPath,

        [Parameter(Mandatory=$false)]
        [Bool]$multipleinputs
    )

    process {
            $folders = Get-ChildItem -Path $Path -Directory
            
            # Get Folder Size
            $FolderSizes = foreach ($folder in $folders) {
                $size = (Get-ChildItem -Path $folder.FullName -File -Recurse -Exclude $ExcludedPath | Measure-Object -Property Length -Sum).Sum
                $sizeInTB = $size / 1TB

                [PSCustomObject]@{
                    FolderName = $folder.Name
                    SizeInTB = [Math]::Round($sizeInTB, 2)
                }
            }

            $EmailFolderSize = $FolderSizes | Where-Object { $_.FolderName -notlike $ExcludedPath } | Group-Object FolderName | ForEach-Object {
                if ($_.Count -gt 1 -or $multipleinputs) {
                    [PSCustomObject]@{
                        Company = $_.Group.Foldername[0]
                        SizeInTB  = ($_.Group.SizeInTB | Measure-Object -Sum).Sum
                    }
                } else {
                    [PSCustomObject]@{
                        Company = $_.Group.Foldername
                        SizeInTB  = ($_.Group.SizeInTB | Measure-Object -Average).Average
                    }
                }
            }
        $EmailFolderSize | Format-Table -AutoSize | Out-String | ForEach-Object { $_.TrimEnd() } | Out-File -FilePath $OutputPath -Append
        }
}

Write-Host "Starting script..."
try {
    New-Item -ItemType Directory -Path $nfp

    # This is where the magic happens, run the function here to get your data.
    Get-FolderDataSize -Path $abdpath -ExcludedPath $excludedfolder -OutputPath $abddata
    Get-FolderDataSize -Path $abepath -ExcludedPath $excludedfolder -OutputPath $abedata
    Get-FolderDataSize -Path $obpath -ExcludedPath $excludedfolder -OutputPath $obdata
    Get-FolderDataSize -Path $totalpath -ExcludedPath $excludedfolder -OutputPath $totaldata

    Test-Path $abddata, $abedata, $obdata, $totaldata

    # This section is to get and add the content to the body of the email.
    $abdbody = Get-Content -Path $abedata | Out-String
    $abebody = Get-Content -Path $abddata | Out-String
    $obbody = Get-Content -Path $obdata | Out-String
    $totalbody = Get-Content -Path $totaldata | Out-String

    # Sending Email Message
    # Message Body cannot be pulled from outside of the Try block, so the data cannot be added - this is a timing issue within PowerShell
    $Message['Body'] = "This is just where you put the body of your email" + $abddata + "some more info" + $abedata + $obdata + $totaldata
    Send-MailMessage @Message
    
    Start-Sleep -Seconds 10   # Not required, mainly used so the data is deleted after the email is sent.
    Remove-Item -Path $nfp -Force -Recurse   # You can hash or remove this line aswell if you don't want to delete the data, but it will merge into the same file and send the content with old + new data.
}

catch {
    # Handle errors
    write-error "Error: $_"
    # you can log or display additional information about the error here
}
Write-Host "Script completed."
