#!/usr/bin/env bash

# Create repo file.
echo "[mongodb-org-3.0]" > /etc/yum.repos.d/mongodb-org-3.0.repo
echo "name=MongoDB Repository" >> /etc/yum.repos.d/mongodb-org-3.0.repo
echo "baseurl=http://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/3.0/x86_64/" >> /etc/yum.repos.d/mongodb-org-3.0.repo
echo "gpgcheck=0" >> /etc/yum.repos.d/mongodb-org-3.0.repo
echo "enabled=1" >> /etc/yum.repos.d/mongodb-org-3.0.repo

# Now install mongo.
sudo yum install -y mongodb-org

# Map the local ./db folder to the local machine.
sudo ln -fs /vagrant/db /srv/db

#TODO: mount existing databases, or create from script.

# Start the server.
sudo service mongod start