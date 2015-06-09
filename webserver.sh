#!/usr/bin/env bash

# We need some java.
sudo yum install java-1.8.0-openjdk -y

# Download Jetty
cd /srv
sudo wget –quiet http://download.eclipse.org/jetty/stable-9/dist/jetty-distribution-9.2.10.v20150310.tar.gz
sudo tar xzvf jetty-distribution-9.2.10.v20150310.tar.gz
mv jetty-distribution-9.2.10.v20150310 jetty

# Create the user and create setup script.
useradd --user-group --shell /bin/false --home-dir /srv/jetty/temp jetty
mkdir -p /srv/jetty/temp
chown -R jetty:jetty /srv/jetty
cp jetty/bin/jetty.sh /etc/init.d/jetty

# Map the local ./www folder to the local machine.
sudo ln -fs /vagrant/www /srv/www
chown --recursive jetty /srv/www/
sudo chmod -R 777 /srv/jetty/temp

# Configure startup.
cd /vagrant/www
java -jar /srv/jetty/start.jar --add-to-start=deploy,http,logging

# Starting up on port < 1024 can only be done by superusers.
# This sed is here for example.
sed -i "s/jetty.port=8080/jetty.port=8080/g" /srv/www/start.ini

echo "JETTY_HOME=/srv/jetty" > /etc/default/jetty
echo "JETTY_BASE=/srv/www" >> /etc/default/jetty
echo "TMPDIR=/srv/jetty/temp" >> /etc/default/jetty

# Add to chkconfig so it starts on boot.
sudo chkconfig --add jetty
sudo chkconfig jetty on

service jetty start