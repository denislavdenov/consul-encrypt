SERVER_COUNT = 3
CONSUL_VER = "1.4.2"
LOG_LEVEL= "debug" #The available log levels are "trace", "debug", "info", "warn", and "err". If empty - default is "info"

Vagrant.configure("2") do |config|
  config.vm.synced_folder ".", "/vagrant", disabled: false
  config.vm.provider "virtualbox" do |v|
    v.memory = 512
    v.cpus = 2
  
  end
  (1..SERVER_COUNT).each do |i|
    config.vm.define "consul-server#{i}" do |node|
      node.vm.box = "denislavd/xenial64"
      node.vm.hostname = "consul-server#{i}"
      node.vm.provision :shell, path: "scripts/provision.sh", env: {"SERVER_COUNT" => SERVER_COUNT, "CONSUL_VER" => CONSUL_VER, "LOG_LEVEL" => LOG_LEVEL}
      node.vm.network "private_network", ip: "10.10.56.1#{i}"
    end
  end

  config.vm.define "client-3" do |client3|
    client3.vm.box = "denislavd/base-xenial64"
    client3.vm.hostname = "client-3"
    client3.vm.provision :shell, path: "scripts/provision.sh", env: {"CONSUL_VER" => CONSUL_VER, "LOG_LEVEL" => LOG_LEVEL}
    client3.vm.provision :shell, path: "scripts/conf-dnsmasq.sh"
    client3.vm.provision :shell, path: "scripts/keyvalue.sh"
    client3.vm.network "private_network", ip: "10.10.66.13"
  end
  config.vm.define "client-nginx1" do |nginx|
    nginx.vm.box = "denislavd/nginx64"
    nginx.vm.hostname = "client-nginx1"
    nginx.vm.provision :shell, path: "scripts/provision.sh", env: {"CONSUL_VER" => CONSUL_VER, "LOG_LEVEL" => LOG_LEVEL}
    nginx.vm.provision :shell, path: "scripts/check_nginx.sh"
    nginx.vm.network "private_network", ip: "10.10.66.11"
    nginx.vm.network "forwarded_port", guest: 80, host: 8080
  end
  config.vm.define "client-nginx2" do |nginx2|
    nginx2.vm.box = "denislavd/nginx64"
    nginx2.vm.hostname = "client-nginx2"
    nginx2.vm.provision :shell, path: "scripts/provision.sh", env: {"CONSUL_VER" => CONSUL_VER, "LOG_LEVEL" => LOG_LEVEL}
    nginx2.vm.provision :shell, path: "scripts/check_nginx.sh"
    nginx2.vm.network "private_network", ip: "10.10.66.12"
    nginx2.vm.network "forwarded_port", guest: 80, host: 8081
  end
  
end