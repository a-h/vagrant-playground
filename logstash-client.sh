# Add the key for elastic search, it's part of the same group.
rpm --import http://packages.elasticsearch.org/GPG-KEY-elasticsearch

# Enable time server, or the times might not match.
sudo yum install ntp

# Create a config file.
cat > /etc/yum.repos.d/logstash-forwarder.repo <<end_of_forwarder_config
[logstash-forwarder]
name=logstash-forwarder repository
baseurl=http://packages.elasticsearch.org/logstashforwarder/centos
gpgcheck=1
gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch
enabled=1
end_of_forwarder_config

# Install
yum -y install logstash-forwarder

# Copy the server certificate to the client.
scp root@192.168.80.0:/etc/pki/tls/certs/logstash-forwarder.crt /tmp
cp /tmp/logstash-forwarder.crt /etc/pki/tls/certs/

# Set up logstash
cat > /etc/logstash-forwarder.conf <<end_of_logstash_forwarder_configuration
{
  # The network section covers network configuration :)
  "network": {
    # A list of downstream servers listening for our messages.
    # logstash-forwarder will pick one at random and only switch if
    # the selected one appears to be dead or unresponsive
    "servers": [ "192.168.80.0:5000" ],

    # The path to your client ssl certificate (optional)
    #"ssl certificate": "./logstash-forwarder.crt",
    # The path to your client ssl key (optional)
    #"ssl key": "./logstash-forwarder.key",

    # The path to your trusted ssl CA file. This is used
    # to authenticate your downstream server.
    "ssl ca": "/etc/pki/tls/certs/logstash-forwarder.crt",

    # Network timeout in seconds. This is most important for
    # logstash-forwarder determining whether to stop waiting for an
    # acknowledgement from the downstream server. If an timeout is reached,
    # logstash-forwarder will assume the connection or server is bad and
    # will connect to a server chosen at random from the servers list.
    "timeout": 300
  },

  # The list of files configurations
  "files": [
    # An array of hashes. Each hash tells what paths to watch and
    # what fields to annotate on events from those paths.
    {
      "paths": [
        "/var/log/nginx/access.log"
       ],
      "fields": { "type": "nginx-access" }
    }
    #{
      "paths": [
        # single paths are fine
        #"/var/log/messages",
        # globs are fine too, they will be periodically evaluated
        # to see if any new files match the wildcard.
        "/var/log/*.log"
      ],

      # A dictionary of fields to annotate on each event.
      #"fields": { "type": "syslog" }
    #}, {
      # A path of "-" means stdin.
      #"paths": [ "-" ],
      #"fields": { "type": "stdin" }
    #}, {
      #"paths": [
        #"/var/log/apache/httpd-*.log"
      #],
      #"fields": { "type": "apache" }
    #}
  ]
}
end_of_logstash_forwarder_configuration