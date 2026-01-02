# -*- mode: ruby -*-
# vi: set ft=ruby :
require "fileutils"

NUM_WORKERS = 2
BASE_IP = 200
INVENTORY_FILE = "inventory.cfg"
SHARED_DIR = "./shared" # local shared dir
VMS_SHARED_DIR = "/mnt/shared" # shared dir inside VMs

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  # Disable the defualt shared folder
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Mount Shared Folder
  config.vm.synced_folder SHARED_DIR, VMS_SHARED_DIR,
  create: true,
  owner: "vagrant",
  group: "vagrant",
  mount_options: ["dmode=775,fmode=664"]


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
end

# Copy Vagrant's auto-generated inventory to the root directory
vagrant_inventory = '.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory'
if File.exist?(vagrant_inventory)
  FileUtils.cp(vagrant_inventory, INVENTORY_FILE)
end

