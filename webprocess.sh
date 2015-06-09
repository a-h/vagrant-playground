#!/usr/bin/env bash

# We need some java.
sudo yum install java-1.8.0-openjdk -y

# Map the local ./www folder to the local machine.
sudo ln -fs /vagrant/webprocess /srv/www

# Configure startup.
cd /vagrant/webprocess
# nohup tells the server not to warn on background processes on disconnect.
# The ampersand stops the system from pausing.
nohup java -jar example-api.jar &