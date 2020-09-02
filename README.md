# Liferay Cluster in PorwerShell

## ElasticSearch

### 1 - Open PowerShell ISE with administrator privileges

### 2 - Copy content of elasticsearch.ps1 to ISE

### 3 - See the sections: 

      # Configure elasticsearch.yaml
      ...
      # Configure JVM
      ...
      
### 4 - Execute with F5

## JBoss + Liferay

### 1 - Open PowerShell ISE with administrator privileges

### 2 - Copy content of liferay_jboss.ps1 to ISE

### 3 - Execute with F5

### 4 - See the files:

      standalone.conf.bat (JVM)
      standalone.xml (DataSource)
      com.liferay.portal.search.elasticsearch6.configuration.ElasticsearchConfiguration.config (ElasticSearch configurations for liferay)
