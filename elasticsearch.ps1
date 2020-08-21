###################################################################################
## Liferay Cluster with Powershell                                               ##
## Script for install ElasticSearch on Windows Server 2016                       ##
## Author: https://github.com/Iakim                                              ##
## Simplicity is the ultimate degree of sophistication                           ##
###################################################################################

# Universal Vars
# This variables you can use to determine install or not ElasticSearch like a Windows Service
# If $INSTALL = 1 the ElasticSearch Install like a Windows Service, If other 0, start from CMD
# INSTALL
$INSTALL = 1
# NOT INSTALL
#$INSTALL = 0
$VERSION = "6.5.1"
$HOSTNAME = hostname
$IP = Get-NetIPAddress -AddressFamily IPv4 | findstr IPAddress | findstr /v 127.0.0.1 | Foreach {"$(($_ -split '\s+',4)[2])"}
$CLUSTER_NAME = "liferay-cluster"
$FILECONFIG = "C:\elasticsearch-$VERSION\config\elasticsearch.yml"
$BATPLUGIN = "C:\elasticsearch-$VERSION\config\plugins.bat"
$JVMCONFIG = "C:\elasticsearch-$VERSION\config\jvm.options"

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
echo $JAVAPATHNAME
[System.Environment]::SetEnvironmentVariable("JAVA_HOME","C:\Program Files\Java\$JAVAPATHNAME",[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable("JAVA_HOME","C:\Program Files\Java\$JAVAPATHNAME",[System.EnvironmentVariableTarget]::User)

# Install ElasticSearch
New-Item -ItemType directory -Path C:\elasticsearch-$VERSION
Invoke-WebRequest https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$VERSION.zip -OutFile C:\elasticsearch-$VERSION\elasticsearch-$VERSION.zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$ZIPFILE, [string]$OUTPATH)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZIPFILE, $OUTPATH)
}
Unzip C:\elasticsearch-$VERSION\elasticsearch-$VERSION.zip C:\elasticsearch-$VERSION\elasticsearch-$VERSION
Move-Item C:\elasticsearch-$VERSION\elasticsearch-$VERSION\elasticsearch-$VERSION\* C:\elasticsearch-$VERSION
Remove-Item –recurse -Path C:\elasticsearch-$VERSION\elasticsearch-$VERSION
Rename-Item $FILECONFIG "$FILECONFIG.old"
New-Item $FILECONFIG
Rename-Item $JVMCONFIG "$JVMCONFIG.old"
New-Item $JVMCONFIG

# Configure elasticsearch.yaml
Add-Content $FILECONFIG "bootstrap.memory_lock: false"
Add-Content $FILECONFIG "cluster.name: $CLUSTER_NAME"
Add-Content $FILECONFIG "network.host: $IP"
Add-Content $FILECONFIG "node.data: true"
Add-Content $FILECONFIG "node.ingest: false"
Add-Content $FILECONFIG "node.master: true"
Add-Content $FILECONFIG "node.max_local_storage_nodes: 1"
Add-Content $FILECONFIG "node.name: $HOSTNAME"
Add-Content $FILECONFIG "path.data: C:\elasticsearch-$VERSION\data"
Add-Content $FILECONFIG "path.logs: C:\elasticsearch-$VERSION\logs"
Add-Content $FILECONFIG "xpack.license.self_generated.type: basic"
Add-Content $FILECONFIG "xpack.security.enabled: false"
Add-Content $FILECONFIG "action.destructive_requires_name: true"
Add-Content $FILECONFIG "http.compression: true"
Add-Content $FILECONFIG 'http.cors.allow-origin: "*"'
Add-Content $FILECONFIG "http.cors.enabled: true"
Add-Content $FILECONFIG "thread_pool.search.queue_size: 5000"
Add-Content $FILECONFIG "thread_pool.search.min_queue_size: 1000"

# Configure JVM
Add-Content $JVMCONFIG "-XX:+UseConcMarkSweepGC"
Add-Content $JVMCONFIG "-XX:CMSInitiatingOccupancyFraction=75"
Add-Content $JVMCONFIG "-XX:+UseCMSInitiatingOccupancyOnly"
Add-Content $JVMCONFIG "-XX:+AlwaysPreTouch"
Add-Content $JVMCONFIG "-Xss1m"
Add-Content $JVMCONFIG "-Djava.awt.headless=true"
Add-Content $JVMCONFIG "-Dfile.encoding=UTF-8"
Add-Content $JVMCONFIG "-Djna.nosys=true"
Add-Content $JVMCONFIG "-XX:-OmitStackTraceInFastThrow"
Add-Content $JVMCONFIG "-Dio.netty.noUnsafe=true"
Add-Content $JVMCONFIG "-Dio.netty.noKeySetOptimization=true"
Add-Content $JVMCONFIG "-Dio.netty.recycler.maxCapacityPerThread=0"
Add-Content $JVMCONFIG "-Dlog4j.shutdownHookEnabled=false"
Add-Content $JVMCONFIG "-Dlog4j2.disable.jmx=true"
Add-Content $JVMCONFIG "-Djava.io.tmpdir=${ES_TMPDIR}"
Add-Content $JVMCONFIG "-XX:+HeapDumpOnOutOfMemoryError"
Add-Content $JVMCONFIG "-XX:HeapDumpPath=data"
Add-Content $JVMCONFIG "-XX:ErrorFile=logs/hs_err_pid%p.log"
Add-Content $JVMCONFIG "8:-XX:+PrintGCDetails"
Add-Content $JVMCONFIG "8:-XX:+PrintGCDateStamps"
Add-Content $JVMCONFIG "8:-XX:+PrintTenuringDistribution"
Add-Content $JVMCONFIG "8:-XX:+PrintGCApplicationStoppedTime"
Add-Content $JVMCONFIG "8:-Xloggc:logs/gc.log"
Add-Content $JVMCONFIG "8:-XX:+UseGCLogFileRotation"
Add-Content $JVMCONFIG "8:-XX:NumberOfGCLogFiles=32"
Add-Content $JVMCONFIG "8:-XX:GCLogFileSize=64m"
Add-Content $JVMCONFIG "-Xmx2048m"
Add-Content $JVMCONFIG "-Xms2048m"

# Install Plugins
Add-Content $BATPLUGIN "@echo off"
Add-Content $BATPLUGIN "C:\elasticsearch-$VERSION\bin\elasticsearch-plugin.bat install analysis-icu & C:\elasticsearch-$VERSION\bin\elasticsearch-plugin.bat install analysis-kuromoji & C:\elasticsearch-$VERSION\bin\elasticsearch-plugin.bat install analysis-smartcn & C:\elasticsearch-$VERSION\bin\elasticsearch-plugin.bat install analysis-stempel"
Start-Process $BATPLUGIN
Start-Sleep 40

# Start
if("$INSTALL" -eq 1){
  Start-Process C:\elasticsearch-$VERSION\bin\elasticsearch-service.bat install
  Start-Sleep 5
  Set-Service elasticsearch-service-x64 -StartupType Automatic
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
    Set-ServiceRecovery -ServiceDisplayName "Elasticsearch 6.5.1"
  Start-Service elasticsearch-service-x64
}else {
   Start-Process "C:\elasticsearch-$VERSION\bin\elasticsearch.bat"
}
