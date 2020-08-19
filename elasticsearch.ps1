##############################################################################################
# NAME:                Script for install elasticsearch on Windows Server 2016
# AUTHORS:             Isaac de Moraes, Wesley Erick, Kaio Santos, Edyel Mitzi and Wesley Lago
##############################################################################################

$version = "6.5.1"

New-Item -ItemType directory -Path C:\elasticsearch-$version
Invoke-WebRequest https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$version.msi -OutFile C:\elasticsearch-$version.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I C:\elasticsearch-$version.msi /qn INSTALLDIR="C:\elasticsearch-$version'
