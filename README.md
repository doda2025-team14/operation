# SMS Checker

This is an SMS Checker app that identifies whether an SMS message is considered a spam or not (ham).

## Run the application

### Requirements

To run this application, you need to have Docker and Docker Compose installed.

### Process

1. Clone the operation repository.

2. Create a  ```.env``` file and define the exposed port of the localhost. If you don't define any, 8080 will be used as a default port. Here is an example of the contents of the ```.env``` file: 

```HOST_PORT=9000```

3. To start the application, run the following command ```docker compose up -d```

If the command runs successfully, congratulations! The web app can be accessed by typing this link on the browser: ```http://localhost:{HOST_PORT}/sms/```. For example, if you use the default port, type: ```http://localhost:8080/sms/```.

## Provisioning

We provide the necessary files to provision a Kubernetes cluster. All VMs run on the `bento/ubuntu-24.04` base system. The cluster consists of:
- A controller (192.168.56.100): 4GB memory, 2 cores
- Variable number of workers (192.168.56.101+): 6GB memory, 2 cores

3 playbooks are used to configure the VM software:
1. `general.yml`: general configuration applied to all VMs
2. `ctrl.yml`: extra configuration applied only to the controller
3. `node.yml`: extra configuration applied only to the workers

### Prerequisites

- Vagrant
- VirtualBox
- Ansible

### Usage

1. Optional: Place your public SSH key in the 'ssh-keys' directory
2. Navigate to this directory in your terminal
3. Run `vagrant up` to create and provision the virtual machines
4. Run `vagrant halt` to stop the VMs
