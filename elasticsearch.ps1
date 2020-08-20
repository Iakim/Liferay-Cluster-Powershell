##############################################################################################
# NAME:                Script for install elasticsearch on Windows Server 2016
# AUTHORS:             Isaac de Moraes, Wesley Erick, Kaio Sousa, Edyel Mitzi and Wesley Lago
##############################################################################################

$version = "6.5.1"
$hostname = hostname
$ip = Get-NetIPAddress -AddressFamily IPv4
$cluster_name = "liferay-cluster"

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
Rename-Item C:\elasticsearch-$version\config\elasticsearch.yml C:\elasticsearch-$version\config\elasticsearch.yml.save
New-Item  C:\elasticsearch-$version\config\elasticsearch.yml


# Configure elasticsearch.yaml
echo "bootstrap.memory_lock: false" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "cluster.name: $cluster_name" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "network.host: $ip" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "node.data: true" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "node.ingest: false" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "node.master: true" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "node.max_local_storage_nodes: 1" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "node.name: $hostname" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "path.data: C:\elasticsearch-$version\data" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "path.logs: C:\elasticsearch-$version\logs" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "xpack.license.self_generated.type: basic" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "xpack.security.enabled: false" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "action.destructive_requires_name: true" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "http.compression: true" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo 'http.cors.allow-origin: "*"' >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "http.cors.enabled: true" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "thread_pool.search.queue_size: 5000" >> C:\elasticsearch-$version\config\elasticsearch.yml
echo "thread_pool.search.min_queue_size: 1000" >> C:\elasticsearch-$version\config\elasticsearch.yml

# Install Plugins
cmd.exe /k "C:\elasticsearch-$version\bin\elasticsearch-plugin.bat install analysis-icu"
cmd.exe /k "C:\elasticsearch-$version\bin\elasticsearch-plugin.bat install analysis-kuromoji"
cmd.exe /k "C:\elasticsearch-$version\bin\elasticsearch-plugin.bat install analysis-smartcn"
cmd.exe /k "C:\elasticsearch-$version\bin\elasticsearch-plugin.bat install analysis-stempel"

# Start
cmd.exe /k "C:\elasticsearch-$version\bin\elasticsearch.bat"
