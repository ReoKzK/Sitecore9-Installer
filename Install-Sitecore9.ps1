# Sitecore 9 Installer
# Credits to George Chang - https://blogs.perficient.com/sitecore/2017/10/23/how-to-install-sitecore-9-with-the-sitecore-install-framework/

# Parameters config
$installConfig =
@{
    SitecoreVersion = "9.0.2 rev. 180604"

    Prefix = "sc902.test"
    WebRoot = "C:\inetpub\wwwroot"
    
    # Dependencies
    DependenciesFolder = "Dependencies"
    IsDependenciesFolderRelative = $TRUE
    LicenseFile = "license.xml"

    # SQL Server
    SqlServer = "DESKTOP-5S7KJRS"
    SqlAdminUser = "sa"
    SqlAdminPassword = "Qwerty!2345" 
    
    # Solr
    SolrUrl = "https://localhost:8983/solr"
    SolrRoot = "c:\Program Files\solr-6.6.2"
    SolrService = "solr622-1"
}

if ($installConfig.IsDependenciesFolderRelative -eq $TRUE)
{
    $dependenciesRoot = Join-Path $PSScriptRoot -ChildPath $installConfig.DependenciesFolder
}

$licensePath = Join-Path $dependenciesRoot -ChildPath $installConfig.LicenseFile

$XConnectCollectionService = "$($installConfig.Prefix).xconnect"
$sitecoreSiteName = "$($installConfig.Prefix).local"
$certificateName = "$($installConfig.Prefix).xconnect_client" 

function Install-XConnect 
{
    # Install client certificate for xConnect     
    $certParams = 
    @{     
        Path = "$dependenciesRoot\xconnect-createcert.json"     
        CertificateName = $certificateName 
    } 
    
    Install-SitecoreConfiguration @certParams -Verbose
    
    # Install Solr cores for xConnect
    $solrParams = 
    @{
        Path = "$dependenciesRoot\xconnect-solr.json"     
        SolrUrl = $installConfig.SolrUrl
        SolrRoot = $installConfig.SolrRoot  
        SolrService = $installConfig.SolrService  
        CorePrefix = $installConfig.Prefix
    } 
    
    Install-SitecoreConfiguration @solrParams -Verbose
    
    # Deploy xconnect instance 
    $xconnectParams = 
    @{
        Path = "$dependenciesRoot\xconnect-xp0.json"     
        Package = "$dependenciesRoot\Sitecore $($installConfig.SitecoreVersion) (OnPrem)_xp0xconnect.scwdp.zip"
        LicenseFile = $licensePath
        Sitename = $XConnectCollectionService   
        XConnectCert = $certParams.CertificateName    
        SqlDbPrefix = $installConfig.Prefix
        SqlServer = $installConfig.SqlServer
        SqlAdminUser = $installConfig.SqlAdminUser
        SqlAdminPassword = $installConfig.SqlAdminPassword
        SolrCorePrefix = $installConfig.Prefix
        SolrUrl = $installConfig.SolrUrl
    }

    Install-SitecoreConfiguration @xconnectParams -Verbose
}

function Install-Sitecore 
{
    # Install Solr cores for Sitecore 
    $solrParams = 
    @{
        Path = "$dependenciesRoot\sitecore-solr.json"
        SolrUrl = $installConfig.SolrUrl    
        SolrRoot = $installConfig.SolrRoot  
        SolrService = $installConfig.SolrService   
        CorePrefix = $installConfig.Prefix
    } 
    Install-SitecoreConfiguration @solrParams -Verbose
    
    # Install sitecore instance 
    $sitecoreParams = 
    @{
        Path = "$dependenciesRoot\sitecore-XP0.json"
        Package = "$dependenciesRoot\Sitecore $($installConfig.SitecoreVersion) (OnPrem)_single.scwdp.zip" 
        LicenseFile = $licensePath
        SqlDbPrefix = $installConfig.Prefix
        SqlServer = $installConfig.SqlServer  
        SqlAdminUser = $installConfig.SqlAdminUser     
        SqlAdminPassword = $installConfig.SqlAdminPassword     
        SolrCorePrefix = $installConfig.Prefix
        SolrUrl = $installConfig.SolrUrl
        XConnectCert = $certificateName
        Sitename = $sitecoreSiteName         
        XConnectCollectionService = "https://$XConnectCollectionService"    
    }

    Install-SitecoreConfiguration @sitecoreParams -Verbose
}

function Set-Environment 
{
    try
    {
        Write-Host "Setting localenv in Web.config"
    
        $SitecoreSiteRoot = Join-Path $installConfig.WebRoot -ChildPath $sitecoreSiteName
        
        $webConfigPath = "$SitecoreSiteRoot\Web.config"
        $localEnvName = "Local"
        
        # Add Local localenv variable
        $RptKeyFound = 0;
        $xml = (Get-Content $webConfigPath) -as [Xml];                # Create the XML Object and open the web.config file
        $root = $xml.get_DocumentElement();                           # Get the root element of the file
        
        foreach ($item in $root.appSettings.add)                      # loop through the child items in appsettings
        {
            if ($item.key -eq "localenv:define")                      # If the desired element already exists
            {
                $RptKeyFound = 1;                                     # Set the found flag
            }
        }
        
        if ($RptKeyFound -eq 0)                                       # If the desired element does not exist
        {
            $newEl = $xml.CreateElement("add");                       # Create a new Element
            $nameAtt1 = $xml.CreateAttribute("key");                  # Create a new attribute "key"
            $nameAtt1.psbase.value = "localenv:define";               # Set the value of "key" attribute
            $newEl.SetAttributeNode($nameAtt1);                       # Attach the "key" attribute
            $nameAtt2 = $xml.CreateAttribute("value");                # Create "value" attribute 
            $nameAtt2.psbase.value = "$localEnvName";                 # Set the value of "value" attribute
            $newEl.SetAttributeNode($nameAtt2);                       # Attach the "value" attribute
            $xml.configuration["appSettings"].AppendChild($newEl);    # Add the newly created element to the right position
        } 
        
        $xml.Save($webConfigPath)   
    }
    catch
    {
        Write-Host "Failed to set localenv variable to Local" -ForegroundColor Red
        throw
    }
}

Install-XConnect 
Install-Sitecore 
Set-Environment 

