class WebSiteDetail
{
    [string]$Name
    [int]$Port
    [string]$NetTcpBinding
}


$certStore = "cert:\LocalMachine\My"

$cert = (Get-ChildItem $certStore | 
    where-object { $_.Subject -like "*localhost*" } | 
    Select-Object -First 1).Thumbprint

$guid = [guid]::NewGuid().ToString("B")
    
$publishFolder = "C:\publish"

$WebSites = [WebSiteDetail[]] @()

$WebSites += new-object WebSiteDetail -Property @{ Name="affiliate-vendor-api"; Port=1733 }
$WebSites += new-object WebSiteDetail -Property @{ Name="agency-api"; Port=1731 }
$WebSites += new-object WebSiteDetail -Property @{ Name="client-api"; Port=1732 }
$WebSites += new-object WebSiteDetail -Property @{ Name="corporate"; Port=1721 }
$WebSites += new-object WebSiteDetail -Property @{ Name="fs-web-utility"; Port=1722; NetTcpBinding="808:*" }
$WebSites += new-object WebSiteDetail -Property @{ Name="identity-api"; Port=1734 }
$WebSites += new-object WebSiteDetail -Property @{ Name="staffing-api"; Port=1727 }

foreach($website in $websites)
{
    $siteName = $website.Name 
    $sitePort = $website.Port 
    $netTcpBinding = $website.NetTcpBinding
    $sitePath = "$publishFolder\$siteName"

    "*** Processing $siteName ***"

    New-Item -ItemType directory "$sitePath" -Force -ErrorAction Ignore

    New-WebAppPool -name $siteName 
    New-WebSite -Name $siteName -PhysicalPath "$sitePath" -ssl -SslFlags 0 -ApplicationPool $siteName -Port $sitePort     
    $binding = Get-WebBinding -Name $siteName -Protocol "https"
    $binding.AddSslCertificate($cert, "my")

    if ($netTcpBinding -ne $null -and $netTcpBinding -ne "")
    {
        Set-ItemProperty "IIS:\Sites\$siteName" -name EnabledProtocols -Value "http,net.tcp"
        New-ItemProperty -path "IIS:\Sites\$siteName" -name bindings -value @{protocol="net.tcp";bindingInformation="$netTcpBinding"}
    }
}

<#
foreach($website in $websites)
{
    remove-WebSite -Name $website.Name
    remove-WebAppPool -name $website.Name
}
#>