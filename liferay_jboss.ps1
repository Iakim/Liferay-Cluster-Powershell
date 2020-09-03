###################################################################################
## Liferay Cluster with Powershell                                               ##
## Script for install JBoss Wildfly on Windows Server 2016                       ##
## Author: https://github.com/Iakim                                              ##
## Simplicity is the ultimate degree of sophistication                           ##
###################################################################################

$FILECONFIG = "C:\liferay\wildfly-18.0.1.Final\standalone\configuration\standalone.xml"
$WARFOLDER = "C:\liferay\wildfly-18.0.1.Final\standalone\deployments\ROOT.war"
$DEPFOLDER = "C:\liferay\wildfly-18.0.1.Final\modules\com\liferay\portal\main"

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
$JAVA_HOME = "C:\Program Files\Java\$JAVAPATHNAME"

# Install JBoss Wildfly 18.0.1
New-Item -ItemType directory -Path C:\liferay
Invoke-WebRequest https://download.jboss.org/wildfly/18.0.1.Final/wildfly-18.0.1.Final.zip -OutFile C:\wildfly-18.0.1.Final.zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$ZIPFILE, [string]$OUTPATH)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZIPFILE, $OUTPATH)
}
Unzip C:\wildfly-18.0.1.Final.zip C:\liferay
Rename-Item $FILECONFIG "$FILECONFIG.old"
Invoke-WebRequest https://raw.githubusercontent.com/Iakim/Liferay-Cluster-Powershell/master/standalone.xml -OutFile $FILECONFIG

# Set JBOSS_HOME
[System.Environment]::SetEnvironmentVariable("JBOSS_HOME","C:\liferay\wildfly-18.0.1.Final",[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable("JBOSS_HOME","C:\liferay\wildfly-18.0.1.Final",[System.EnvironmentVariableTarget]::User)
$JBOSS_HOME = "C:\liferay\wildfly-18.0.1.Final"

# Install JBoss as Service
New-Item -ItemType directory -Path C:\liferay\wildfly-18.0.1.Final\modules\net\sourceforge\jtds\main
Rename-Item "C:\liferay\wildfly-18.0.1.Final\bin\standalone.conf.bat" "C:\liferay\wildfly-18.0.1.Final\bin\standalone.conf.bat.old"
Invoke-WebRequest "https://raw.githubusercontent.com/Iakim/Liferay-Cluster-Powershell/master/standalone.conf.bat" -OutFile C:\liferay\wildfly-18.0.1.Final\bin\standalone.conf.bat
Copy-Item -Path "C:\liferay\wildfly-18.0.1.Final\docs\contrib\scripts\service" "C:\liferay\wildfly-18.0.1.Final\bin" -Recurse
Start-Process "cmd.exe" "/k C:\liferay\wildfly-18.0.1.Final\bin\service\service.bat install /startup /name WildFly_Liferay /display WildFly_Liferay"
Start-Sleep 5
function Set-ServiceRecovery{
  [alias('Set-Recovery')]
  param
  (
    [string] [Parameter(Mandatory=$true)] $ServiceDisplayName,
    [string] $action1 = "restart",
    [int] $time1 =  30000,
    [string] $action2 = "restart",
    [int] $time2 =  30000,
    [string] $actionLast = "restart",
    [int] $timeLast = 30000,
    [int] $resetCounter = 4000
  )
  $services = Get-CimInstance -ClassName 'Win32_Service' | Where-Object {$_.DisplayName -imatch $ServiceDisplayName}
  $action = $action1+"/"+$time1+"/"+$action2+"/"+$time2+"/"+$actionLast+"/"+$timeLast
  foreach ($service in $services){
    $output = sc.exe failure $($service.Name) actions= $action reset= $resetCounter
  }
}
Set-ServiceRecovery -ServiceDisplayName "WildFly_Liferay"

# Install Liferay 7.3.2CE GA3
New-Item -ItemType directory -Path $WARFOLDER
New-Item -ItemType directory -Path $DEPFOLDER
New-Item -ItemType directory -Path C:\liferay\data
New-Item -ItemType directory -Path C:\liferay\deploy
New-Item -ItemType directory -Path C:\liferay\logs
New-Item -ItemType directory -Path C:\liferay\osgi

Invoke-WebRequest https://raw.githubusercontent.com/Iakim/Liferay-Cluster-Powershell/master/module.xml -OutFile $DEPFOLDER\module.xml
$URLDEP=(Invoke-WebRequest -UseBasicParsing "https://sourceforge.net/settings/mirror_choices?projectname=lportal&filename=Liferay%20Portal/7.3.2%20GA3/liferay-ce-portal-dependencies-7.3.2-ga3-20200519164024819.zip&selected=svwh").Content | %{[regex]::matches($_, '(?:Please use this <a href=")(.*)(?:">)').Groups[1].Value}
Invoke-WebRequest -UseBasicParsing -OutFile C:\dependencies.zip $URLDEP
$URLOSGI=(Invoke-WebRequest -UseBasicParsing "https://sourceforge.net/settings/mirror_choices?projectname=lportal&filename=Liferay%20Portal/7.3.2%20GA3/liferay-ce-portal-osgi-7.3.2-ga3-20200519164024819.zip&selected=svwh").Content | %{[regex]::matches($_, '(?:Please use this <a href=")(.*)(?:">)').Groups[1].Value}
Invoke-WebRequest -UseBasicParsing -OutFile C:\osgi.zip $URLOSGI
$URLWAR=(Invoke-WebRequest -UseBasicParsing "https://sourceforge.net/settings/mirror_choices?projectname=lportal&filename=Liferay%20Portal/7.3.2%20GA3/liferay-ce-portal-7.3.2-ga3-20200519164024819.war&selected=svwh").Content | %{[regex]::matches($_, '(?:Please use this <a href=")(.*)(?:">)').Groups[1].Value}
Invoke-WebRequest -UseBasicParsing -OutFile C:\ROOT.war $URLWAR

Invoke-WebRequest "https://search.maven.org/remotecontent?filepath=it/dontesta/labs/liferay/portal/db/liferay-portal-database-all-in-one-support/1.2.1/liferay-portal-database-all-in-one-support-1.2.1.jar" -OutFile C:\liferay-portal-database-all-in-one-support-1.2.1.jar
Invoke-WebRequest "https://raw.githubusercontent.com/Iakim/Liferay-Cluster-Powershell/master/module_jtds.xml" -OutFile C:\liferay\wildfly-18.0.1.Final\modules\net\sourceforge\jtds\main\module.xml
Invoke-WebRequest "https://github.com/Iakim/Liferay-Cluster-Powershell/raw/master/jtds-1.3.1.jar" -OutFile C:\liferay\wildfly-18.0.1.Final\modules\net\sourceforge\jtds\main\jtds-1.3.1.jar
Invoke-WebRequest "https://github.com/Iakim/Liferay-Cluster-Powershell/raw/master/portal-ext.properties" -OutFile C:\liferay\portal-ext.properties
Invoke-WebRequest "https://raw.githubusercontent.com/Iakim/Liferay-Cluster-Powershell/master/com.liferay.portal.search.elasticsearch6.configuration.ElasticsearchConfiguration.config" -OutFile C:\liferay\osgi\configs\com.liferay.portal.search.elasticsearch6.configuration.ElasticsearchConfiguration.config
Unzip C:\dependencies.zip $DEPFOLDER
Move-Item $DEPFOLDER\liferay-ce-portal-dependencies-7.3.2-ga3\* $DEPFOLDER
Remove-Item -Path $DEPFOLDER\liferay-ce-portal-dependencies-7.3.2-ga3
Unzip C:\osgi.zip C:\liferay\osgi
Move-Item C:\liferay\osgi\liferay-ce-portal-osgi-7.3.2-ga3\* C:\liferay\osgi
Remove-Item -Path C:\liferay\osgi\liferay-ce-portal-osgi-7.3.2-ga3
Unzip C:\ROOT.war $WARFOLDER
Move-Item C:\liferay-portal-database-all-in-one-support-1.2.1.jar $WARFOLDER\WEB-INF\lib
New-Item -ItemType File "$WARFOLDER".dodeploy
Start-Service WildFly_Liferay
