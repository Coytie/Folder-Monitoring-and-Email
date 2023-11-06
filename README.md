# Folder-Monitoring-and-Email

PowerShell Automation script that runs on your server/pc and emails a report on the amount of storage space consumed by each folder recursively. </br></br>
Due to the nature of how the information is gathered in PowerShell, you will need to make sure to set a location for the data to be saved temporarily due to the output conversion to a string cannot be read. </br> </br>
The vault in use will be one that is stored locally, you can use Azure Key Vault if you wish instead.

### Modules Required
```
Install-Module -Name Microsoft.PowerShell.SecretManagement -Force
Install-Module -Name Microsoft.PowerShell.SecretStore -Force
```

## Creating Secret Vault
Import both modules mentioned above. Firstly you will need to create your vault, in this case we will set the name to TheVaultOfTestings
```
Register-SecretVault -Name TheVaultOfTestings -ModuleName Microsoft.PowerShell.SecretStore
```
Next we will need to create the secret in the newly created vault, this is where the password (or username if you wish to do that as well). We will name it SuperSecretSecret
```
Set-Secret -Vault TheVaultOfTestings -Name SuperSecretSecret -Secret Thispasswordislols01!
```
That's it! Atleast that is if you want to put in the password for the vault everytime and this not be automatic! Because this is all stored locally on the server and for the current user, we can remove this password for the vault as it is used to to store the credentials on the script. To do this, we need to do the following:
```
Set-SecretStoreConfiguration -Authentication None
```
And that's it! You can now point your script to the SuperSecretSecret key in your script.
