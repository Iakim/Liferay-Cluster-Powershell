##############################################################################################
# NAME:                Script for install elasticsearch on Windows Server 2016
# AUTHORS:             Isaac de Moraes, Wesley Erick, Kaio Sousa, Edyel Mitzi and Wesley Lago
##############################################################################################

$version = "6.5.1"
$hostname = hostname
$ip = Get-NetIPAddress -AddressFamily IPv4 | findstr IPAddress | findstr /v 127.0.0.1 | Foreach {"$(($_ -split '\s+',4)[2])"}
$cluster_name = "liferay-cluster"
$fileconfig = "C:\elasticsearch-$version\config\elasticsearch.yml"
$batplugin = "C:\elasticsearch-$version\config\plugins.bat"

# Install Java
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$URL=(Invoke-WebRequest -UseBasicParsing https://www.java.com/en/download/manual.jsp).Content | %{[regex]::matches($_, '(?:<a title="Download Java software for Windows \(64-bit\)" href=")(.*)(?:">)').Groups[1].Value}
Invoke-WebRequest -UseBasicParsing -OutFile jre8.exe $URL
Start-Process .\jre8.exe -argumentlist '/s INSTALL_SILENT=1 STATIC=0 AUTO_UPDATE=0 WEB_JAVA=1 WEB_JAVA_SECURITY_LEVEL=H WEB_ANALYTICS=0 EULA=0 REBOOT=0 NOSTARTMENU=0 SPONSORS=0 /L c:\jre8.log' -wait
echo $?
[System.Environment]::SetEnvironmentVariable('JAVA_HOME','C:\Program Files\Java\jre1.8.0_261',[System.EnvironmentVariableTarget]::Machine)

New-Item -ItemType directory -Path C:\elasticsearch-$version
Invoke-WebRequest https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$version.zip -OutFile C:\elasticsearch-$version\elasticsearch-$version.zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}
Unzip C:\elasticsearch-$version\elasticsearch-$version.zip C:\elasticsearch-$version\elasticsearch-$version
Move-Item C:\elasticsearch-$version\elasticsearch-$version\elasticsearch-$version\* C:\elasticsearch-$version
Remove-Item –recurse -Path C:\elasticsearch-$version\elasticsearch-$version
Rename-Item $fileconfig $fileconfig.save
New-Item $fileconfig


# Configure elasticsearch.yaml

Add-Content $fileconfig "bootstrap.memory_lock: false"
Add-Content $fileconfig "cluster.name: $cluster_name"
Add-Content $fileconfig "network.host: $ip"
Add-Content $fileconfig "node.data: true"
Add-Content $fileconfig "node.ingest: false"
Add-Content $fileconfig "node.master: true"
Add-Content $fileconfig "node.max_local_storage_nodes: 1"
Add-Content $fileconfig "node.name: $hostname"
Add-Content $fileconfig "path.data: C:\elasticsearch-$version\data"
Add-Content $fileconfig "path.logs: C:\elasticsearch-$version\logs"
Add-Content $fileconfig "xpack.license.self_generated.type: basic"
Add-Content $fileconfig "xpack.security.enabled: false"
Add-Content $fileconfig "action.destructive_requires_name: true"
Add-Content $fileconfig "http.compression: true"
Add-Content $fileconfig 'http.cors.allow-origin: "*"'
Add-Content $fileconfig "http.cors.enabled: true"
Add-Content $fileconfig "thread_pool.search.queue_size: 5000"
Add-Content $fileconfig "thread_pool.search.min_queue_size: 1000"

# Install Plugins
Add-Content $batplugin "@echo off"
Add-Content $batplugin "C:\elasticsearch-$version\bin\elasticsearch-plugin.bat install analysis-icu & C:\elasticsearch-$version\bin\elasticsearch-plugin.bat install analysis-kuromoji & C:\elasticsearch-$version\bin\elasticsearch-plugin.bat install analysis-smartcn & C:\elasticsearch-$version\bin\elasticsearch-plugin.bat install analysis-stempel"
Start-Process $batplugin

# Start
Start-Process "C:\elasticsearch-$version\bin\elasticsearch.bat"
