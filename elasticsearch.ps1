##############################################################################################
# NAME:                Script for install elasticsearch on Windows Server 2016
# AUTHORS:             Isaac de Moraes, Wesley Erick, Kaio Sousa, Edyel Mitzi and Wesley Lago
##############################################################################################

$version = "6.5.1"
$hostname = hostname
$ip = Get-NetIPAddress -AddressFamily IPv4
$cluster_name = "liferay-cluster"

New-Item -ItemType directory -Path C:\elasticsearch-$version
Invoke-WebRequest https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$version.msi -OutFile C:\elasticsearch-$version.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\elasticsearch-$version.msi /qn INSTALLDIR="C:\elasticsearch-$version'

# Configure elasticsearch.yaml
echo "bootstrap.memory_lock: false" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "cluster.name: $cluster_name" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "network.host: $ip" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "node.data: true" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "node.ingest: false" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "node.master: true" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "node.max_local_storage_nodes: 1" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "node.name: $hostname" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "path.data: C:\elasticsearch-$version\data" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "path.logs: C:\elasticsearch-$version\logs" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "xpack.license.self_generated.type: basic" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "xpack.security.enabled: false" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "action.destructive_requires_name: true" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "http.compression: true" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo 'http.cors.allow-origin: "*"' >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "http.cors.enabled: true" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "thread_pool.search.queue_size: 5000" >> C:\elasticsearch-$version\conf\elasticsearch.yaml
echo "thread_pool.search.min_queue_size: 1000" >> C:\elasticsearch-$version\conf\elasticsearch.yaml

# Start service
Get-Service Elasticsearch | Start-Service
