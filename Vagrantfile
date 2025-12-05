# -*- mode: ruby -*-
# vi: set ft=ruby :
require "fileutils"

NUM_WORKERS = 2
BASE_IP = 200
INVENTORY_FILE = "inventory.cfg"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Control node
  config.vm.define "ctrl" do |ctrl|
    ctrl.vm.hostname = "ctrl"
    ctrl.vm.network "private_network", ip: "192.168.56.#{BASE_IP}"

    ctrl.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = "2"
    end

    # Provision with Ansible
    ctrl.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/general.yml"
      ansible.extra_vars = { num_workers: NUM_WORKERS, base_ip: BASE_IP }
    end
    ctrl.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/ctrl.yml"
      ansible.extra_vars = { num_workers: NUM_WORKERS, base_ip: BASE_IP }
    end
  end

  # Worker nodes
  (1..NUM_WORKERS).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}"
      node.vm.network "private_network", ip: "192.168.56.#{BASE_IP + i}"

      node.vm.provider "virtualbox" do |vb|
        vb.memory = "6144"
        vb.cpus = "2"
      end

      # Provision with Ansible
      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "playbooks/general.yml"
        ansible.extra_vars = { num_workers: NUM_WORKERS, base_ip: BASE_IP }
      end
      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "playbooks/node.yml"
        ansible.extra_vars = { num_workers: NUM_WORKERS, base_ip: BASE_IP }
      end
    end
  end
  
  servers = []
  
  servers << {
    "name" => "ctrl",
    "ip_addr" => "192.168.56.#{BASE_IP}",
    "role" => "ctrl"
  }

  (1..NUM_WORKERS).each do |i|
    servers << {
      "name" => "node-#{i}",
      "ip_addr" => "192.168.56.#{BASE_IP + i}",
      "role" => "worker"
    }
  end


  File.open(INVENTORY_FILE, "w") do |f|
    f.puts "[all]"
    servers.each do |server|
      f.puts "#{server['name']} ansible_host=#{server['ip_addr']}"
    end
  end
end
