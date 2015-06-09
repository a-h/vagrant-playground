#!/usr/bin/env bash

# CentOS ships with Python 2, so we need to add a software collection
# and set it to replace Python 2.6.
yum install centos-release-SCL -y
yum install python33 -y
scl enable python33 bash

# Map the local ./www folder to the local machine.
sudo ln -fs /vagrant/django /srv/www

# Configure startup.
cd /vagrant/django
# nohup tells the server not to warn on background processes on disconnect.
# The ampersand stops the system from pausing.
nohup python manage.py runserver &