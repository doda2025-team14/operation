# SMS Checker

This repository contains coursework for the [DevOps for Distributed Apps (CS4295)](https://studyguide.tudelft.nl/courses/study-guide/educations/14776) course at [Delft University of Technology (Netherlands, EU)](https://se.ewi.tudelft.nl/teaching/) by [Dr. Sebastian Proksch](https://proks.ch/). We extend a simple [SMS Checker app](https://github.com/proksch/sms-checker) that identifies whether an SMS message is considered a spam or not (ham). More specifically, we focus on providing the necessary configuration and automation to operate the application and perform continuous experimentation.

## Organization and Repositories

You are currently in the `operation` repository which acts as a central hub from which we can deploy, orchestrate, and monitor the application. Beyond this, we have three other repositories in our organization:

- [`app`](https://github.com/doda2025-team14/app): Hosts the web application frontend (JavaScript) and backend REST API (Spring Boot) that connects users to the `model-service`.
- [`model-service`](https://github.com/doda2025-team14/model-service): Provides the machine learning model (Python) and serves predictions to `app` via a REST API.
- [`lib-version`](https://github.com/doda2025-team14/lib-version): Contains a version-aware Maven library that provides version information to other components.

### Team Members

| Name                    | GitHub Username      | Student Number | Email                                 |
|-------------------------|----------------------|----------------|---------------------------------------|
| Boris Annink            | Borito185            |                | B.R.M.Annink@student.tudelft.nl       |
| Conall Lynch            | conalllynch2015-a11y | 6182488        | C.J.Lynch@student.tudelft.nl          |
| Wilhelm Marcu           | wmarcu               | 5245788        | W.P.A.Marcu@student.tudelft.nl        |
| Jeffrey Meerovici Goryn | jmeerovici           |                | J.G.MeeroviciGoryn@student.tudelft.nl |
| Alessandro Valmori      | alevu3344            |                | A.Valmori@student.tudelft.nl          |

### Additional Documentation

We provide links to other resources for readers who wish to gain a deeper understanding of the project:

- [`docs/deployment`](https://github.com/doda2025-team14/operation/blob/master/docs/deployment.md): For understanding the structure and data flow of the final deployment.
- [`docs/extension`](https://github.com/doda2025-team14/operation/blob/master/docs/extension.md): For gaining insight into the limitations/shortcomings of this project and how to improve upon them in future work.
- [`docs/activity`](https://github.com/doda2025-team14/operation/blob/master/docs/ACTIVITY.md): For a high level overview of the weekly contributions of each team member
- [`project backlog`](https://github.com/orgs/doda2025-team14/projects/4/views/1): For a detailed collection of issues and merge requests and an insight into the workload distribution.



## Configuration and Options

### Environment Variables

| Variable | Scope |Description | Default |
|--------|------|-------|---------|
| `MODEL_HOST` | `app` | The hostname of the model-service that the frontend app should call to get SMS predictions | ??? |
| `API_KEY` | `app` | Secret API key | ??? |
| `ENABLE_CACHE` | `app` | Tells the frontend whether to send the X-Cache-Enabled: true header to the model-service. This enables caching for requests which is part of the experiment performed in the canary release | `false` |
| `MODEL_URL` | `model-service` | URL to download the pre-trained SMS spam detection model (model-release.tar.gz). The model-service downloads and extracts this file at startup if not already present. | ??? |
| `APP_PORT` | `model-service` | Port that the Flask app will listen on inside the container. | ??? |

### Helm Chart Values

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



## Cluster Setup and Provisioning

We provide the necessary configuration to setup a cluster for the application to run in. We support two use cases: Minikube for quick, lightweight testing, and dedicated VMs for more control and flexibility.

### Setting up Minikube

#### Prerequisites

- Minikube
- Kubectl
- Istioctl

#### Instructions

1. Delete current minikube cluster (if present): `minikube delete`
2. Create a new cluster: `minikube start --memory=6144 --cpus=4 --driver=docker`
3. Enable ingress addon: `minikube addons enable ingress`
4. Install Istio to the cluster: `istioctl install -y`

We provide a script `setup-minikube.sh` for ease of use which performs the above instructions.

### Provisioning Virtual Machines

#### Prerequisites
- VirtualBox
- Vagrant
- Ansible

#### Virtual Machine Details

All VMs run on the `bento/ubuntu-24.04` base system. The cluster specification can be found in the [`Vagrantfile`](https://github.com/doda2025-team14/operation/blob/master/Vagrantfile) and consists of:
- A controller `(192.168.56.200)`: 4GB memory, 2 cores
- Variable number of workers (default 2) `(192.168.56.201+)`: 6GB memory, 2 cores

Note: we made the decision to deviate from the standard IP addresses specified in the assignment instructions. Instead of starting from IP address `192.168.56.100`, we start from `192.168.56.200` to avoid a common networking configuration error on the host machine related to a running DHCP server on the same IP.

We use Ansible playbooks to configure the VM software:
- `general.yml`: general configuration applied to all VMs (K8s tools, containerd, networking)
- `ctrl.yml`: extra configuration applied only to the controller (cluster init, Flannel, Helm)
- `node.yml`: extra configuration applied only to the workers (join cluster)
- `flannel.yml`: Flannel CNI network configuration
- `finalization.yml`: post-provisioning setup run from host (MetalLB, Ingress Controller, Dashboard, Istio)


#### Instructions

1. Optional: Place your public SSH key in the `ssh-keys` directory. This will automatically copy your key to each VM during provisioning, allowing you to immediately connect.

2. Run `vagrant up` to create and provision the VMs. This runs `general.yml`, `ctrl.yml`, and `node.yml` automatically.

3. After VMs are up, run the finalization playbook from the host to install cluster services:
   ```bash
   ansible-playbook -i inventory.cfg playbooks/finalization.yml \
     --private-key=.vagrant/machines/ctrl/virtualbox/private_key \
     -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"' \
     -u vagrant --limit ctrl
   ```

4. Deploy the application using Helm:
   ```bash
   KUBECONFIG=./playbooks/admin.conf helm install my-release chart/ --dependency-update
   ```

5. Run `vagrant halt` to stop the VMs or `vagrant destroy` for complete removal.

#### Cluster Services & IPs

After provisioning, the following services are available:

| Service | IP | Port |
|---------|-----|------|
| Ingress Controller (nginx) | 192.168.56.93 | 80, 443 |
| Istio Gateway | 192.168.56.94 | 80, 443 |
| Kubernetes Dashboard | Via ingress | - |



## Deploying and Running the Application

We provide pre-built images which you can use to run the application. The available images, along with other packages, are published to [GitHub Packages](https://github.com/orgs/doda2025-team14/packages). The application can be run either through Docker containers or using Kubernetes.

### Run using Docker containers

#### Prerequisites

- Docker
- Docker Compose

#### Instructions

 To start the application, run the following command `docker compose up -d`.

### Run using Kubernetes

#### Prerequisites

- A running cluster (see previous section)
- Helm

#### Instructions

We provide a helm chart in the `/chart` directory for easily deploying the application to a Kubernetes cluster. To deploy, run: `helm install my-release chart/ --dependency-update`

### Exposed Endpoints



## Monitoring

### Metrics

### Alerting



## Legacy

Anything below this section is part of the old readme and is not yet moved/adapted into the new readme

## Run the application

### Requirements

To run this application, you need to have Docker and Docker Compose installed.

### Process

1. Clone the operation repository.

2. Create a  ```.env``` file and define the exposed port of the localhost. If you don't define any, 8080 will be used as a default port. Here is an example of the contents of the ```.env``` file: 

```HOST_PORT=9000```

3. To start the application, run the following command ```docker compose up -d```

If the command runs successfully, congratulations! The web app can be accessed by typing this link on the browser: ```http://localhost:{HOST_PORT}/sms/```. For example, if you use the default port, type: ```http://localhost:8080/sms/```.



## Deployment
We provide a helm chart in the /chart directory for easily deploying the application to a Kubernetes cluster.

### Prerequisites
- Kubernetes cluster (e.g. Minikube)
- Helm
- Ingress Controller (optional, but required for external access)

### Accessing the Application

If Ingress is enabled, you can access the application at the configured host (default: `http://team14.local`). Ensure your `/etc/hosts` or DNS is configured to point `team14.local` to your Ingress Controller's IP.

### Deploy with Minikube
The following instructions are for starting and deploying to a local Minikube cluster

1. Start the cluster: `minikube start --driver=docker`
2. Make sure the ingress addon is enabled: `minikube addons enable ingress`
3. Deploy the application to the cluster: `helm install my-release chart/ --dependency-update`
4. View the available services: `minikube service list`
5. Access the application using the URL displayed by the previous step or via `http://team14.local` if configured.
6. Remove the application from the cluster: `helm uninstall my-release`
7. Run `minikube stop` to stop the cluster or `minikube delete` for complete removal.

### Deploy to Kubernetes Cluster on Vagrant VMs
The following instructions are for deploying to a cluster on vagrant virtual machines.

1. Ensure you have [Vagrant](https://github.com/hashicorp/vagrant) installed on your host machine.
2. (If Required) Destory any previous VM instances: `vagrant destroy -f`
3. Run `vagrant up --provision` to set up and provision the VMs.
4. Once all VMs have provisioned, run `ansible-playbook -i 192.168.56.200, ./playbooks/finalization.yml -u vagrant   --private-key .vagrant/machines/ctrl/virtualbox private_key -e "ansible_ssh_common_args='-o StrictHostKeyChecking=no'"   -e ansible_ssh_timeout=60 ` to run the finalization playbook in the ctrl node.
5. Merge the cluster's KUBECONFIG with your local one `KUBECONFIG=~/.kube/config:/path/to/admin.conf kubectl config view --merge --flatten > ~/.kube/config.new mv ~/.kube/config.new ~/.kube/config`. The default path to admin.conf is `./shared/admin.conf` as defined in the Vagrantfile. Check the context names: `kubectl config get-contexts`
6. Change kubectl context to the cluster: `kubectl config use-context <context-name>` (by default `kubernetes-admin@kubernetes`)
7. Verify helm is using the correct context (should use kubectl's by default): `helm list`
8. Deploy the application to the cluster: `helm install my-release chart/ --dependency-update`


### Metrics
- The metrics page can be accessed in plaintext via `http://<app_url>/metrics`.
- This endpoint is scraped by Prometheus to collect data regarding:
-- Ham/Spam Identification
-- Total Active Users
-- Latency Distribution

- Prometheus defaults to port 9090 and you can port-forward this to your local machine using `kubectl port-forward svc/my-release-kube-prometheus-prometheus 9090:9090` 
- You can query the following to get their related metrics ({} -> Optional Arguments):
-- frontend_sms_requests_total{status="success",result="ham"}: Count of messages identified as "Ham" (i.e., not Spam)
-- frontend_sms_requests_total{status="success",result="spam"}: Count of messages identified as "Spam"
-- frontend_active_users: Total number of active users (within the last 5 mins)
-- frontend_prediction_latency_seconds_bucket{status="success",le="0.1"/"0.2"/"0.5"}: Latency Historgram regions
-- frontend_prediction_latency_seconds_count{status="success"}: total requests
-- frontend_prediction_latency_seconds_sum{status="success"}: "total" latentcy (combine with above to get average)

- To add more metrics, add a collection mechanism to FrontendController and append the output String of MetricsController to export it.

### Accessing the dashboard
1. Port forward the dashboard to the localhost using: `kubectl port-forward svc/my-release-grafana 3000:80`
2. Go to localhost:3000
3. Login using admin and "42" as password
4. On the left click dashboards and look for App and A4