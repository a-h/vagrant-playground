#!/usr/bin/env bash
set -x
trap read debug

# See instructions at https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-4-on-centos-7
# exit 0

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
echo "[elasticsearch-1.4]" > /etc/yum.repos.d/elasticsearch.repo
echo "name=Elasticsearch repository for 1.4.x packages" >> /etc/yum.repos.d/elasticsearch.repo
echo "baseurl=http://packages.elasticsearch.org/elasticsearch/1.4/centos" >> /etc/yum.repos.d/elasticsearch.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/elasticsearch.repo
echo "gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch" >> /etc/yum.repos.d/elasticsearch.repo
echo "enabled=1" >> /etc/yum.repos.d/elasticsearch.repo

# Do it
yum -y install elasticsearch-1.4.4

# Consider modifying /etc/elasticsearch/elasticsearch.yml to remove access outside of localhost.

# Start it up.
systemctl start elasticsearch.service

# Start it when the system starts.
systemctl enable elasticsearch.service

##########
# Kibana #
##########

cd ~; wget https://download.elasticsearch.org/kibana/kibana/kibana-4.0.1-linux-x64.tar.gz
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

echo "input {" > /etc/logstash/conf.d/01-lumberjack-input.conf
echo "  lumberjack {" >> /etc/logstash/conf.d/01-lumberjack-input.conf
echo "    port => 5000" >> /etc/logstash/conf.d/01-lumberjack-input.conf
echo "    type => \"logs\"" >> /etc/logstash/conf.d/01-lumberjack-input.conf
echo "    ssl_certificate => \"/etc/pki/tls/certs/logstash-forwarder.crt\"" >> /etc/logstash/conf.d/01-lumberjack-input.conf
echo "    ssl_key => \"/etc/pki/tls/private/logstash-forwarder.key\"" >> /etc/logstash/conf.d/01-lumberjack-input.conf
echo "  }" >> /etc/logstash/conf.d/01-lumberjack-input.conf
echo "}" >> /etc/logstash/conf.d/01-lumberjack-input.conf

# Create filter for syslog messages
echo "filter {" > /etc/logstash/conf.d/10-syslog.conf
echo "  if [type] == \"syslog\" {" >> /etc/logstash/conf.d/10-syslog.conf
echo "    grok {" >> /etc/logstash/conf.d/10-syslog.conf
echo "      match => { \"message\" => \"%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}\" }" >> /etc/logstash/conf.d/10-syslog.conf
echo "      add_field => [ \"received_at\", \"%{@timestamp}\" ]" >> /etc/logstash/conf.d/10-syslog.conf
echo "      add_field => [ \"received_from\", \"%{host}\" ]" >> /etc/logstash/conf.d/10-syslog.conf
echo "    }" >> /etc/logstash/conf.d/10-syslog.conf
echo "    syslog_pri { }" >> /etc/logstash/conf.d/10-syslog.conf
echo "    date {" >> /etc/logstash/conf.d/10-syslog.conf
echo "      match => [ \"syslog_timestamp\", \"MMM  d HH:mm:ss\", \"MMM dd HH:mm:ss\" ]" >> /etc/logstash/conf.d/10-syslog.conf
echo "    }" >> /etc/logstash/conf.d/10-syslog.conf
echo "  }" >> /etc/logstash/conf.d/10-syslog.conf
echo "}" >> /etc/logstash/conf.d/10-syslog.conf

# Setup elastic search location
echo "output {" > /etc/logstash/conf.d/30-lumberjack-output.conf
echo "  elasticsearch { host => localhost }" >> /etc/logstash/conf.d/30-lumberjack-output.conf
echo "  stdout { codec => rubydebug }" >> /etc/logstash/conf.d/30-lumberjack-output.conf
echo "}" >> /etc/logstash/conf.d/30-lumberjack-output.conf