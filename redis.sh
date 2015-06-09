#!/usr/bin/env bash

yum install epel-release -y
yum install redis -y
service redis start