# SIF Installation Script

## Verify elevated
## https://superuser.com/questions/749243/detect-if-powershell-is-running-as-administrator
$elevated = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
if($elevated -eq $false)
{
    throw "In order to install SIF, please run this script elevated."
}

# Add the Sitecore MyGet repository to PowerShell
# Check first if already added

Get-PSRepository SitecoreGallery -ErrorVariable errors -ErrorAction SilentlyContinue | out-null

if ($errors.Count -gt 0)
{
	Write-Host "Resitering SitecoreGallery MyGet repository"
    Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2
}

# Install the Sitecore Install Framwork module
Write-Host "Installing Sitecore Install Framwork module"
Install-Module SitecoreInstallFramework

# Install the Sitecore Fundamentals module (provides additional functionality for local installations like creating self-signed certificates)
Write-Host "Installing Sitecore Fundamentals module"
Install-Module SitecoreFundamentals

# Import the modules into your current PowerShell context (if necessary)
Write-Host "Importing modules"
Import-Module SitecoreFundamentals
Import-Module SitecoreInstallFramework

Write-Host "SIF installation completed." -ForegroundColor Green
