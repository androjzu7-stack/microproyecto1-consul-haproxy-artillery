# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  IPS = {
    "lb"     => "192.168.100.10",
    "web1"   => "192.168.100.11",
    "web2"   => "192.168.100.12",
    "client" => "192.168.100.13"
  }

  # -------- BALANCEADOR (HAProxy + Consul) ----------
  config.vm.define :lb do |lb|
    lb.vm.hostname = "lb"
    lb.vm.network :private_network, :ip => IPS["lb"]

    lb.vm.network "forwarded_port", :guest => 80,   :host => 8080, :auto_correct => true
    lb.vm.network "forwarded_port", :guest => 1936, :host => 8404, :auto_correct => true
    lb.vm.network "forwarded_port", :guest => 8500, :host => 8500, :auto_correct => true

    lb.vm.provision "shell", :path => "scripts/common.sh"
    lb.vm.provision "shell", :path => "scripts/consul.sh",
      :args => ["lb", IPS["lb"], "true", "3", "#{IPS["lb"]},#{IPS["web1"]},#{IPS["web2"]}"]
    lb.vm.provision "shell", :path => "scripts/lb.sh"
  end

  # -------- WEB 1 ----------
  config.vm.define :web1 do |web1|
    web1.vm.hostname = "web1"
    web1.vm.network :private_network, :ip => IPS["web1"]

    web1.vm.provision "shell", :path => "scripts/common.sh"
    web1.vm.provision "shell", :path => "scripts/consul.sh",
      :args => ["web1", IPS["web1"], "true", "3", "#{IPS["lb"]},#{IPS["web1"]},#{IPS["web2"]}"]
    web1.vm.provision "shell", :path => "scripts/web.sh",
      :args => ["web1", IPS["web1"], "3", "3000"]
  end

  # -------- WEB 2 ----------
  config.vm.define :web2 do |web2|
    web2.vm.hostname = "web2"
    web2.vm.network :private_network, :ip => IPS["web2"]

    web2.vm.provision "shell", :path => "scripts/common.sh"
    web2.vm.provision "shell", :path => "scripts/consul.sh",
      :args => ["web2", IPS["web2"], "true", "3", "#{IPS["lb"]},#{IPS["web1"]},#{IPS["web2"]}"]
    web2.vm.provision "shell", :path => "scripts/web.sh",
      :args => ["web2", IPS["web2"], "3", "3000"]
  end

  # -------- CLIENT (Artillery) ----------
  config.vm.define :client do |client|
    client.vm.hostname = "client"
    client.vm.network :private_network, :ip => IPS["client"]

    client.vm.provision "shell", :path => "scripts/common.sh"
    client.vm.provision "shell", :path => "scripts/client.sh", :args => [IPS["lb"]]
  end
end