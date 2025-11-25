# -*- mode: ruby -*-
# vi: set ft=ruby :

NUM_WORKERS = 2

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Control node
  config.vm.define "ctrl" do |ctrl|
    ctrl.vm.hostname = "ctrl"
    ctrl.vm.network "private_network", ip: "192.168.56.100"

    ctrl.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = "2"
    end

    # Provision with Ansible
    ctrl.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/general.yml"
      ansible.extra_vars = { num_workers: NUM_WORKERS }
    end
    ctrl.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbooks/ctrl.yml"
      ansible.extra_vars = { num_workers: NUM_WORKERS }
    end
  end

  # Worker nodes
  (1..NUM_WORKERS).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}"
      node.vm.network "private_network", ip: "192.168.56.10#{i}"

      node.vm.provider "virtualbox" do |vb|
        vb.memory = "6144"
        vb.cpus = "2"
      end

      # Provision with Ansible
      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "playbooks/general.yml"
        ansible.extra_vars = { num_workers: NUM_WORKERS }
      end
      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "playbooks/node.yml"
        ansible.extra_vars = { num_workers: NUM_WORKERS }
      end
    end
  end
end
