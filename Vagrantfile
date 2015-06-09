# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "chef/centos-6.5"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.define "webserver" do |webserver|
    webserver.vm.provision "shell", path: "webserver.sh"
    webserver.vm.network :forwarded_port, host: 4567, guest: 8080
    webserver.vm.network "private_network", ip: "192.168.10.0", :netmask => "255.255.0.0"
  end

  config.vm.define "webprocess" do |webprocess|
    webprocess.vm.provision "shell", path: "webprocess.sh"
    webprocess.vm.network :forwarded_port, host: 4568, guest: 8080
    webprocess.vm.network "private_network", ip: "192.168.20.0", :netmask => "255.255.0.0"
  end
 
  config.vm.define "rabbitmq" do |rabbitmq|
    rabbitmq.vm.provision "shell", path: "rabbitmq.sh"
    rabbitmq.vm.network :forwarded_port, host: 5672, guest: 5672
    rabbitmq.vm.network :forwarded_port, host: 15672, guest: 15672
    rabbitmq.vm.network "private_network", ip: "192.168.30.0", :netmask => "255.255.0.0"
  end
  
  config.vm.define "redis" do |redis|
    redis.vm.provision "shell", path: "redis.sh"
    redis.vm.network :forwarded_port, host: 6379, guest: 6379
    redis.vm.network "private_network", ip: "192.168.40.1", :netmask => "255.255.0.0"
  end
  
  config.vm.define "django" do |django|
    django.vm.provision "shell", path: "django.sh"
    django.vm.network :forwarded_port, host: 8001, guest: 8000
    django.vm.network "private_network", ip: "192.168.50.0", :netmask => "255.255.0.0"
  end

  config.vm.define "mysql" do |mysql|
    mysql.vm.provision "shell", path: "mysql.sh"
    mysql.vm.network :forwarded_port, host: 3306, guest: 3306
    mysql.vm.network "private_network", ip: "192.168.60.0", :netmask => "255.255.0.0"
  end

  config.vm.define "mongo" do |mongo|
    mongo.vm.provision "shell", path: "mongo.sh"
    mongo.vm.network :forwarded_port, host: 27017, guest: 27017
    mongo.vm.network "private_network", ip: "192.168.70.0", :netmask => "255.255.0.0"
  end
  
  config.vm.define "elk" do |elk|
    elk.vm.box = "chef/centos-7.0"
    elk.vm.provision "shell", path: "elk.sh"
    elk.vm.network :forwarded_port, host: 5601, guest: 5601
    elk.vm.network "private_network", ip: "192.168.80.0", :netmask => "255.255.0.0"
  end
end
