# Sitecore 9 Installer
# Credits to George Chang - https://blogs.perficient.com/sitecore/2017/10/23/how-to-install-sitecore-9-with-the-sitecore-install-framework/

# Parameters 
$installConfig =
@{
    Prefix = "sc90"
    DependenciesFolder = "Dependencies"

    SqlServer = "DESKTOP-5S7KJRS"
    SqlAdminUser = "sa"
    SqlAdminPassword = "Qwerty!2345" 
}

$PSScriptRoot = "d:\Sitecore versions\Sitecore 9.0.1 rev. 171219 (WDP XP0 packages)"
$LicenseFile = "d:\Licenses\Sitecore\license.xml"
$XConnectCollectionService = "$($installConfig.Prefix).xconnect"
$sitecoreSiteName = "$($installConfig.Prefix).local"
$SolrUrl = "https://localhost:8983/solr"
$SolrRoot = "c:\Program Files\solr-6.6.2"
$SolrService = "solr622"

 
# Install client certificate for xconnect 
$certParams = 
@{     
    Path = "$PSScriptRoot\xconnect-createcert.json"     
    CertificateName = "$($installConfig.Prefix).xconnect_client" 
} 
Install-SitecoreConfiguration @certParams -Verbose

#install solr cores for xdb 
$solrParams = 
@{
    Path = "$PSScriptRoot\xconnect-solr.json"     
    SolrUrl = $SolrUrl    
    SolrRoot = $SolrRoot  
    SolrService = $SolrService  
    CorePrefix = $installConfig.Prefix
} 
Install-SitecoreConfiguration @solrParams -Verbose

#deploy xconnect instance 
$xconnectParams = 
@{
    Path = "$PSScriptRoot\xconnect-xp0.json"     
    Package = "$PSScriptRoot\Sitecore 9.0.1 rev. 171219 (OnPrem)_xp0xconnect.scwdp.zip"
    LicenseFile = $LicenseFile
    Sitename = $XConnectCollectionService   
    XConnectCert = $certParams.CertificateName    
    SqlDbPrefix = $installConfig.Prefix
    SqlServer = $installConfig.SqlServer
    SqlAdminUser = $installConfig.SqlAdminUser
    SqlAdminPassword = $installConfig.SqlAdminPassword
    SolrCorePrefix = $installConfig.Prefix
    SolrURL = $SolrUrl      
}

Install-SitecoreConfiguration @xconnectParams -Verbose

#install solr cores for sitecore 
$solrParams = 
@{
    Path = "$PSScriptRoot\sitecore-solr.json"
    SolrUrl = $SolrUrl
    SolrRoot = $SolrRoot
    SolrService = $SolrService     
    CorePrefix = $installConfig.Prefix
} 
Install-SitecoreConfiguration @solrParams -Verbose
 
# Install sitecore instance 
$sitecoreParams = 
@{     
    Path = "$PSScriptRoot\sitecore-XP0.json"
    Package = "$PSScriptRoot\Sitecore 9.0.1 rev. 171219 (OnPrem)_single.scwdp.zip" 
    LicenseFile = $LicenseFile
    SqlDbPrefix = $installConfig.Prefix
    SqlServer = $installConfig.SqlServer  
    SqlAdminUser = $installConfig.SqlAdminUser     
    SqlAdminPassword = $installConfig.SqlAdminPassword     
    SolrCorePrefix = $installConfig.Prefix
    SolrUrl = $SolrUrl     
    XConnectCert = $certParams.CertificateName     
    Sitename = $sitecoreSiteName         
    XConnectCollectionService = "https://$XConnectCollectionService"    
}

Install-SitecoreConfiguration @sitecoreParams -Verbose