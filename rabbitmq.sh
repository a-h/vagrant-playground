#!/usr/bin/env bash

# RabbitMQ requires Erlang, but both Erland and RabbitMQ are available through EPEL.
yum install epel-release -y

sudo yum install rabbitmq-server -y
bash /usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management
sudo service rabbitmq-server start