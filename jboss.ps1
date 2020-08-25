###################################################################################
## Liferay Cluster with Powershell                                               ##
## Script for install JBoss Wildfly on Windows Server 2016                       ##
## Author: https://github.com/Iakim                                              ##
## Simplicity is the ultimate degree of sophistication                           ##
###################################################################################

$FILECONFIG = C:\liferay\wildfly-18.0.1\standalone\configuration\standalone.xml
$WARFOLDER = C:\liferay\wildfly-18.0.1\standalone\deployments\ROOT.war
$DEPFOLDER = C:\liferay\wildfly-18.0.1\standalone\modules\com\liferay\portal\main

# Install Java
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# This URL was converted by https://sites.google.com/view/java-se-download-url-converter
$URL="https://javadl.oracle.com/webapps/download/GetFile/1.8.0_261-b12/a4634525489241b9a9e1aa73d9e118e6/windows-i586/jdk-8u261-windows-x64.exe?xd_co_f=658408cb-51db-4a2e-b0ec-74337725720b"
Function Get-RedirectedUrl {

    Param (
        [Parameter(Mandatory=$TRUE)]
        [String]$URL
    )

    $REQUEST = [System.Net.WebRequest]::Create($URL)
    $REQUEST.AllowAutoRedirect=$false
    $RESPONSE=$REQUEST.GetResponse()

    If ($RESPONSE.StatusCode -eq "Found")
    {
        $RESPONSE.GetResponseHeader("Location")
    }
}
$JAVAVERSION = [System.IO.Path]::GetFileName((Get-RedirectedUrl $URL)) | ForEach {"$(($_ -split '-',4)[1])"}
$NAMEEXE="java-$JAVAVERSION.exe"
Invoke-WebRequest -UseBasicParsing -OutFile C:\$NAMEEXE $URL
Start-Process C:\$NAMEEXE -argumentlist '/s INSTALL_SILENT=1 STATIC=0 AUTO_UPDATE=0 WEB_JAVA=1 WEB_JAVA_SECURITY_LEVEL=H WEB_ANALYTICS=0 EULA=0 REBOOT=0 NOSTARTMENU=0 SPONSORS=0 /L c:\jre8.log' -wait
echo $?

# Set JAVA_HOME
$JAVAPATHNAME=Get-ChildItem 'C:\Program Files\Java' | Sort-Object -Descending -Property Name | select-Object Name | findstr jdk | select -First 1
[System.Environment]::SetEnvironmentVariable("JAVA_HOME","C:\Program Files\Java\$JAVAPATHNAME",[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable("JAVA_HOME","C:\Program Files\Java\$JAVAPATHNAME",[System.EnvironmentVariableTarget]::User)

# Install JBoss Wildfly 18.0.1
New-Item -ItemType directory -Path C:\liferay
Invoke-WebRequest https://download.jboss.org/wildfly/18.0.1.Final/wildfly-18.0.1.Final.zip -OutFile C:\wildfly-18.0.1.Final.zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$ZIPFILE, [string]$OUTPATH)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZIPFILE, $OUTPATH)
}
Unzip C:\wildfly-18.0.1.Final.zip C:\liferay\wildfly-18.0.1
Rename-Item $FILECONFIG "$FILECONFIG.old"
Invoke-WebRequest https://raw.githubusercontent.com/Iakim/Liferay-Cluster-Powershell/master/standalone.xml -OutFile $FILECONFIG

# Install Liferay 7.3.2CE GA3
New-Item -ItemType directory -Path $WARFOLDER
New-Item -ItemType directory -Path $DEPFOLDER
New-Item -ItemType directory -Path C:\liferay\data
New-Item -ItemType directory -Path C:\liferay\deploy
New-Item -ItemType directory -Path C:\liferay\logs
New-Item -ItemType directory -Path C:\liferay\osgi
Invoke-WebRequest https://raw.githubusercontent.com/Iakim/Liferay-Cluster-Powershell/master/module.xml -OutFile $DEPFOLDER\module.xml
Invoke-WebRequest  "https://sourceforge.net/projects/lportal/files/Liferay%20Portal/7.3.2%20GA3/liferay-ce-portal-dependencies-7.3.2-ga3-20200519164024819.zip/download" -OutFile C:\dependencies.zip
Invoke-WebRequest  "https://sourceforge.net/projects/lportal/files/Liferay%20Portal/7.3.2%20GA3/liferay-ce-portal-osgi-7.3.2-ga3-20200519164024819.zip/download" -OutFile C:\osgi.zip
Invoke-WebRequest  "https://sourceforge.net/projects/lportal/files/Liferay%20Portal/7.3.2%20GA3/liferay-ce-portal-7.3.2-ga3-20200519164024819.war/download" -OutFile C:\ROOT.war
Invoke-WebRequest  "https://search.maven.org/remotecontent?filepath=it/dontesta/labs/liferay/portal/db/liferay-portal-database-all-in-one-support/1.2.1/liferay-portal-database-all-in-one-support-1.2.1.jar" -OutFile C:\liferay-portal-database-all-in-one-support-1.2.1.jar
Unzip C:\dependencies.zip $DEPFOLDER\
Unzip C:\osgi.zip C:\liferay\osgi\
Unzip C:\ROOT.war $WARFOLDER\
Move-Item C:\liferay-portal-database-all-in-one-support-1.2.1.jar $WARFOLDER\WEB-INF\lib\


