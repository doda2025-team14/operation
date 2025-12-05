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
4. Run `vagrant halt` to stop the VMs or `vagrant destroy` for complete removal.

## Deployment
We provide a helm chart in the /chart directory for easily deploying the application to a Kubernetes cluster.

### Prerequisites
- Kubernetes cluster (e.g. Minikube)
- Helm
- Ingress Controller (optional, but required for external access)

### Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `app.replicaCount` | Number of replicas for the app | `1` |
| `app.image.repository` | App image repository | `ghcr.io/doda2025-team14/app` |
| `app.image.tag` | App image tag | `latest` |
| `app.service.port` | App service port | `8080` |
| `app.ingress.enabled` | Enable Ingress for app | `true` |
| `app.ingress.hosts` | Hostnames for Ingress | `[{host: team14.local, paths: [...]}]` |
| `modelService.replicaCount` | Number of replicas for model service | `1` |
| `modelService.image.repository` | Model service image repository | `ghcr.io/doda2025-team14/model-service` |
| `modelService.image.tag` | Model service image tag | `latest` |
| `secrets.apiKey` | API Key (Placeholder for secret management) | `change-me-placeholder` |

### Accessing the Application

If Ingress is enabled, you can access the application at the configured host (default: `http://team14.local`). Ensure your `/etc/hosts` or DNS is configured to point `team14.local` to your Ingress Controller's IP.

### Usage
The following instructions are for starting and deploying to a local Minikube cluster

1. Start the cluster: `minikube start --driver=docker`
2. Make sure the ingress addon is enabled: `minikube addons enable ingress`
3. Deploy the application to the cluster: `helm install my-release chart/ --dependency-update`
4. View the available services: `minikube service list`
5. Access the application using the URL displayed by the previous step or via `http://team14.local` if configured.
6. Remove the application from the cluster: `helm uninstall my-release`
7. Run `minikube stop` to stop the cluster or `minikube delete` for complete removal.

### Accessing the dashboard
1. Port forward the dashboard to the localhost using: `kubectl port-forward svc/my-release-grafana 3000:80`
2. Go to localhost:3000
3. Login using admin and "42" as password
4. On the left click dashboards and look for App and A4


