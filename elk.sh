#!/usr/bin/env bash
# See instructions at https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-4-on-centos-7

# Sync time properly.
sudo yum install ntp

##################
# Elastic Search #
##################

# Install Java 8
cd /opt
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
"http://download.oracle.com/otn-pub/java/jdk/8u40-b25/jre-8u40-linux-x64.tar.gz"
# Extract archive.
tar xvf jre-8*.tar.gz
chown -R root: jre1.8*
# Alias java to use the correct version
sudo alternatives --install /usr/bin/java java /opt/jre1.8*/bin/java 1
# Delete old archive.
rm /opt/jre-8*.tar.gz

# Install Elasticsearch
rpm --import http://packages.elasticsearch.org/GPG-KEY-elasticsearch

# Configure yum to allow it
echo "[elasticsearch-1.6]" > /etc/yum.repos.d/elasticsearch.repo
echo "name=Elasticsearch repository for 1.6.x packages" >> /etc/yum.repos.d/elasticsearch.repo
echo "baseurl=http://packages.elasticsearch.org/elasticsearch/1.6/centos" >> /etc/yum.repos.d/elasticsearch.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/elasticsearch.repo
echo "gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch" >> /etc/yum.repos.d/elasticsearch.repo
echo "enabled=1" >> /etc/yum.repos.d/elasticsearch.repo

# Do it
yum -y install elasticsearch

# Consider modifying /etc/elasticsearch/elasticsearch.yml to remove access outside of localhost.

# Start it up.
systemctl start elasticsearch.service

# Start it when the system starts.
/bin/systemctl daemon-reload
systemctl enable elasticsearch.service

##########
# Kibana #
##########

cd ~; wget https://download.elastic.co/kibana/kibana/kibana-4.0.3-linux-x64.tar.gz
tar xvf kibana-*.tar.gz

# Consider limiting access to kibana by changing the host at ~/kibana-4*/config/kibana.yml

# Move kibana into a better location
sudo mkdir -p /opt/kibana
sudo cp -R ~/kibana-4*/* /opt/kibana/

# Create start up file.
echo "[Service]" >> /etc/systemd/system/kibana4.service
echo "ExecStart=/opt/kibana/bin/kibana" >> /etc/systemd/system/kibana4.service
echo "Restart=always" >> /etc/systemd/system/kibana4.service
echo "StandardOutput=syslog" >> /etc/systemd/system/kibana4.service
echo "StandardError=syslog" >> /etc/systemd/system/kibana4.service
echo "SyslogIdentifier=kibana4" >> /etc/systemd/system/kibana4.service
echo "User=root" >> /etc/systemd/system/kibana4.service
echo "Group=root" >> /etc/systemd/system/kibana4.service
echo "Environment=NODE_ENV=production" >> /etc/systemd/system/kibana4.service
echo "" >> /etc/systemd/system/kibana4.service
echo "[Install]" >> /etc/systemd/system/kibana4.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/kibana4.service

# Start it up.
sudo systemctl start kibana4
sudo systemctl enable kibana4

# If access to Kibana is limited, then we should create a nginx proxy to allow access.

############
# Logstash #
############
# The Logstash package shares the same GPG Key as Elasticsearch, and we already installed that public key, 
# so let's create and edit a new Yum repository file for Logstash:

echo "[logstash-1.5]" > /etc/yum.repos.d/logstash.repo
echo "name=logstash repository for 1.5.x packages" >> /etc/yum.repos.d/logstash.repo
echo "baseurl=http://packages.elasticsearch.org/logstash/1.5/centos" >> /etc/yum.repos.d/logstash.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/logstash.repo
echo "gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch" >> /etc/yum.repos.d/logstash.repo
echo "enabled=1" >> /etc/yum.repos.d/logstash.repo

yum -y install logstash
# Logstash is installed but it is not configured yet.

# using hard coded ip here.
sed -i -e "s/\[ v3_ca \]/[ v3_ca ]\nsubjectAltName = IP: 192.168.80.0/g" /etc/pki/tls/openssl.cnf

# Generate SSL cert.
cd /etc/pki/tls
sudo openssl req -config /etc/pki/tls/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt

mkdir /etc/logstash/
mkdir /etc/logstash/conf.d/

mkdir /opt/logstash/patterns
cat > /opt/logstash/patterns/nginx <<end_of_nginx_pattern
NGUSERNAME [a-zA-Z\.\@\-\+_%]+
NGUSER %{NGUSERNAME}
NGINXACCESS %{IPORHOST:clientip} %{NGUSER:ident} %{NGUSER:auth} \[%{HTTPDATE:timestamp}\] "%{WORD:verb} %{URIPATHPARAM:request} HTTP/%{NUMBER:httpversion}" %{NUMBER:response} (?:%{NUMBER:bytes}|-) (?:"(?:%{URI:referrer}|-)"|%{QS:referrer}) %{QS:agent}
end_of_nginx_pattern
sudo chown logstash:logstash /opt/logstash/patterns/nginx

echo "input {" > /etc/logstash/conf.d/01-lumberjack-input.conf
echo "  lumberjack {" >> /etc/logstash/conf.d/01-lumberjack-input.conf
echo "    port => 5000" >> /etc/logstash/conf.d/01-lumberjack-input.conf
echo "    type => \"logs\"" >> /etc/logstash/conf.d/01-lumberjack-input.conf
echo "    ssl_certificate => \"/etc/pki/tls/certs/logstash-forwarder.crt\"" >> /etc/logstash/conf.d/01-lumberjack-input.conf
echo "    ssl_key => \"/etc/pki/tls/private/logstash-forwarder.key\"" >> /etc/logstash/conf.d/01-lumberjack-input.conf
echo "  }" >> /etc/logstash/conf.d/01-lumberjack-input.conf
echo "}" >> /etc/logstash/conf.d/01-lumberjack-input.conf

# Create filter for syslog messages
cat > /etc/logstash/conf.d/10-syslog.conf <<syslog_filter
filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}
syslog_filter

# Create filter for nginx messages.
cat > /etc/logstash/conf.d/11-nginx.conf <<end_of_logstash_nginx_configuration
filter {
  if [type] == "nginx-access" {
    grok {
      match => { "message" => "%{NGINXACCESS}" }
    }
  }
}
end_of_logstash_nginx_configuration

# Create filter for weblogic messages.
cat > /etc/logstash/conf.d/12-weblogic.conf <<end_of_weblogic_configuration
filter {
  ## WebLogic Server Http Access Log
  if [type] == "weblogic-access" {
    grok {
      match => [ "message", "%{IP:client} - - \[(?<timestamp>%{MONTHDAY}[./-]%{MONTH}[./-]%{YEAR}:%{TIME}\s+%{ISO8601_TIMEZONE})] \"%{WORD:verb} %{URIPATHPARAM:uri}\s+HTTP.+?\" %{NUMBER:status} %{NUMBER:response_time}" ]
    }
    date {
      match => [ "timestamp" , "dd/MMM/yyyy:HH:mm:ss Z" ]
    }
  }
}
end_of_weblogic_configuration

# Setup elastic search location
echo "output {" > /etc/logstash/conf.d/30-lumberjack-output.conf
echo "  elasticsearch { host => localhost }" >> /etc/logstash/conf.d/30-lumberjack-output.conf
echo "  stdout { codec => rubydebug }" >> /etc/logstash/conf.d/30-lumberjack-output.conf
echo "}" >> /etc/logstash/conf.d/30-lumberjack-output.conf

sudo service logstash restart