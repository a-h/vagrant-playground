#!/usr/bin/env bash

# Create repo file.
echo "[mariadb]" > /etc/yum.repos.d/MariaDB.repo
echo "name = MariaDB" >> /etc/yum.repos.d/MariaDB.repo
echo "baseurl = http://yum.mariadb.org/10.0/centos6-amd64" >> /etc/yum.repos.d/MariaDB.repo
echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB" >> /etc/yum.repos.d/MariaDB.repo
echo "gpgcheck=1" >> /etc/yum.repos.d/MariaDB.repo

# Now install maridb.
yum install -y MariaDB-server MariaDB-client

# Map the local ./db folder to the local machine.
sudo ln -fs /vagrant/db /srv/db

#TODO: mount existing databases, or create from script.

# Start the server.
sudo /etc/init.d/mysql start
