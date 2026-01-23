# DODA 2025 Team 14 Activity

## Week 2

### Boris
- https://github.com/doda2025-team14/app/pull/7
- https://github.com/doda2025-team14/model-service/pull/9

This week I set up the project template and created the dockerfiles used to create Docker images. They utilize stages to minimize the size of the final image. Additionally, they support configuring the port and the model host url using environment variables. Lastly, they are able to be built using both the amd64 and arm64 architectures. Implementing f3-f6.

### Elvira
- https://github.com/doda2025-team14/operation/pull/3

I have worked on A1 and have contributed to the docker compose operation and documenting how to start the application (subquestion F7).

### Conall
- https://github.com/doda2025-team14/app/pull/10
- https://github.com/doda2025-team14/model-service/pull/12

Set up GitHub org. Worked on A1F8. Created auto updating versioning for app & model-service based on single source of truth in the pom.xml.

### Wilhelm
- https://github.com/doda2025-team14/lib-version/pull/4
- https://github.com/doda2025-team14/app/pull/8

Worked on assignment 1 F1 and F2. Created issues and GitHub organization project. Setup library to follow Maven project structure and added the corresponding pom.xml. Modified app's pom.xml to depend on library and made hello world controller display library version. Created a GitHub workflow to release the library automatically to GitHub package registry.

### Jeffrey
- https://github.com/doda2025-team14/lib-version/pull/5
- https://github.com/doda2025-team14/model-service/pull/13

Worked on assignment 1 F11. Created a pipeline and script that automates the creation of prerelease timestamps. Contributed a little to F4 so that the pipeline works with multiple architectures. I also reviewed 3 different PR.

### Alessandro
- https://github.com/doda2025-team14/model-service/pull/10

Worked on assignment 1, F9 and F10. In model-service, I implemented a workflow that trains the model and publishes it as a release upon code changes. To complement this, I enhanced the Flask serving application to automatically detect, download, and hot-reload these new model versions from GitHub.

## Week 3

### Boris
- https://github.com/doda2025-team14/operation/pull/35

This week, I worked on connecting the worker nodes to the control node. 
Additionally, I helped fix a few issues we were facing with vagrant.
I implemented step 18-20.

### Elvira
In Week 3, I didn't contribute to the assignment due to system installation issues.

### Conall
https://github.com/doda2025-team14/operation/pull/34

Worked on steps 13-17 of assignment 2. Created the ansible playbook file for the ctrl node in the Kubernetes cluster

### Wilhelm
https://github.com/doda2025-team14/operation/pull/4

Worked on assignment 2 steps 1-5. Created initial Vagrantfile with the necessary configurations for memory, CPU, and networking. Made VMs be provisioned automatically on creation via Ansible with playbooks. Added general playbook tasks for registering public SSH keys for each VM in the cluster and disabled swap in all VMs for compatability with Kubernetes.

### Jeffrey
(https://github.com/doda2025-team14/operation/pull/33)

Worked on assignment 2 steps 9-12. I added the kubernetes repository, Installed the K8s tools, I fine-tune the configuration for the containerd runtime to make it compatible with Ubuntu environment, and Start the kubelet service and register it for auto-start on future system boots.

### Alessandro
https://github.com/doda2025-team14/operation/pull/32

Worked on steps 6, 7 and 8 of assignment 2: I configured kernel modules (overlay, br_netfilter), enabled IPv4 forwarding, and set up /etc/hosts resolution for the cluster.

https://github.com/doda2025-team14/operation/pull/36

Also helped debug a configuration problem, where assigning a x.x.x.100 ip to `ctrl` rendered the join process to time out for some people. Removed hardcoding of IPs from `.yml` playbook files and centralized this in the `Vagrantfile`.





## Week 4

### Boris
- https://github.com/doda2025-team14/model-service/pull/17
- https://github.com/doda2025-team14/operation/pull/66

I started the week with a bug fix where the model-service couldn't start due to improper model linking. 
Additionally, I improved the train workflow to use a version specified in the source.
And I updated the README to include more guidance on how to run the server and what the relevant optional arguments are and do.

For assignment 3, I added the grafana dashboard. It is automatically loaded using helm. it supports multiple time visualisations as well as gauges and a bar chart.

### Elvira
- https://github.com/doda2025-team14/operation/pull/57
- https://github.com/doda2025-team14/operation/pull/58

In week 4, I worked on installing the Nginx Image Controller and the Kubernetes Dashboard from Assignment 2. Additionally, I contributed to Assignment 3 by setting up the installation of Prometheus instance and introducing the ServiceMonitors that bind the application to this instance.

### Conall
https://github.com/doda2025-team14/operation/pull/61
github.com/doda2025-team14/app/pull/13

Created the prometheus scraper for collecting metrics from the app.

### Wilhelm
https://github.com/doda2025-team14/operation/pull/39

Worked on assignment 3 (migrate from Docker Compose to Kubernetes). Created Kubernetes resources for each component of the application: ConfigMap, Deployment, Service and Ingress for `app` and Deployment and Service for `model-service`. Setup basic helm chart to easily deploy the application to a cluster with one command.

### Jeffrey
https://github.com/doda2025-team14/operation/pull/63/files

I worked on assignment 3 a bit but msotly used my time in working on the automation of inventory.cfg

### Alessandro

https://github.com/doda2025-team14/operation/pull/56

Implemented configurable value passing in the helm chart, added a secret.yml.

https://github.com/doda2025-team14/model-service/pull/18

Fixed a bug in `model-service` where the text preprocessor expected the wrong filepath for downloaded model assets.




## Week 5

### Boris
- https://github.com/doda2025-team14/operation/pull/91

With the changes to the Prometheus metrics, I had to redo the Grafana dashboard. I made a visualization for gauges, a histogram, and a few time series. 

### Elvira
LINK

TEXT

### Conall
- https://github.com/doda2025-team14/operation/pull/90

Refactored the Prometheus scraping to not rely on external libraries. Added new metrics,

### Wilhelm
https://github.com/doda2025-team14/operation/pull/82

Worked on setting up traffic monitoring. Added Istio gateway, virtual service, and destination rule resources to configuration. Made Istio compatible with project (specific, targeted sidecar injection instead of global namespace injection which broke other components). Added script for setting up and deploying to Minikube with Istio (for quick reproducible testing rather than using slow VMs).

### Jeffrey
LINK

TEXT

### Alessandro

https://github.com/doda2025-team14/operation/pull/80

https://github.com/doda2025-team14/model-service/pull/20

https://github.com/doda2025-team14/app/pull/14

Added dual deployment capability to operation and updated the workflows to produce experimental builds.



https://github.com/doda2025-team14/operation/pull/82

Helped setting up traffic monitoring using Istio.

## Week 6

### Boris
N/A

### Elvira
LINK

TEXT

### Conall
- https://github.com/doda2025-team14/operation/pull/100
Implemented shared folder at mnt/shared/ in the VMs


TEXT

### Wilhelm
- https://github.com/doda2025-team14/model-service/pull/21
- https://github.com/doda2025-team14/app/pull/16
- https://github.com/doda2025-team14/operation/pull/93

Worked on linking traffic management setup with experiment releases as shown in class. Added more versioning information for app and model-service to debug Istio networking. Implemented sticky sessions using cookies.

### Jeffrey
https://github.com/doda2025-team14/operation/pull/97

This week I worked on trying to limit the access to the application to a maximum of 10 per minute. Currently in progress.

### Alessandro

- https://github.com/doda2025-team14/operation/pull/94
- https://github.com/doda2025-team14/operation/pull/95
- https://github.com/doda2025-team14/model-service/pull/22
- https://github.com/doda2025-team14/app/pull/17
- https://github.com/doda2025-team14/app/pull/18

I have fixed some bugs regarding image tagging in the release workflows of app and model service, I have also helped in making traffic management work in istio.


## Week 7

### Boris
- https://github.com/doda2025-team14/operation/pull/112
- https://github.com/doda2025-team14/operation/pull/113

This week, I updated the docker-compose to include caching the model and started working on improving the routing to v2 version

### Elvira
LINK

TEXT

### Conall
- https://github.com/doda2025-team14/operation/pull/103

Refactored the playbooks to prevent some silent failures when deploying to vagrant VMs, added some explicit directory permissions, updated README to reflect changes.

### Wilhelm
- https://github.com/doda2025-team14/model-service/pull/24
- https://github.com/doda2025-team14/app/pull/24
- https://github.com/doda2025-team14/operation/pull/109

Worked on implementation and documentation for continuous experimentation. Added caching to model-service as part of experiment. Created new endpoint for viewing cache statistics. Modified /sms endpoint to set header for enabling/disabling caching. Made caching an experimental feature by setting environment variable for canary app deployment.

### Jeffrey
- https://github.com/doda2025-team14/operation/pull/97

Continued working on this. Used a lot of the time to understand what was the issue with the rate limiting 

### Alessandro

#### Provisioning and Deployment
- https://github.com/doda2025-team14/operation/pull/88  (opened on Dec 11th but merged this week, has had multiple refactors)

This basically disable istio sidecar injections into the monitoring pods to get everything to work.


#### Versioning and Experimentation
- https://github.com/doda2025-team14/app/pull/20
- https://github.com/doda2025-team14/app/pull/21
- https://github.com/doda2025-team14/app/pull/22
- https://github.com/doda2025-team14/app/pull/23

- https://github.com/doda2025-team14/model-service/pull/23
- https://github.com/doda2025-team14/lib-version/pull/7



What I did is i created a GitHub App and installed it in the org. It's extremely basic and doesn't do anything in particular in itself, it is only used as an actor which is used to push version bumps onto master for stable releases (i.e. when something is merged into master). This was needed because master branches are protected across repositories, and this was, in my opinion, a good way to automate version bumping in a way that doesn't trivialize the assignment at all, and it's a lot less error-prone and automated than manually bumping the version.

#### Multi-arch Builds

- https://github.com/doda2025-team14/app/pull/20

Added multi-architecture builds to the release flow of app.


## Week 8

### Boris
- https://github.com/doda2025-team14/operation/pull/113

Finished working on improving the routing and started with fixing the prometheus connection to the other services and adding the metrics of the experimental version to the grafana.

### Elvira
LINK

TEXT

### Conall
LINK

TEXT

### Wilhelm
- https://github.com/doda2025-team14/operation/pull/122
- https://github.com/doda2025-team14/operation/pull/116

Created proposal for project extension: declarative provisioning using NixOS instead of Ansible. Explained motivation for chosen proposal as well as benefits of NixOS and justified significance to the project. Also improved deployment instructions in README.md and created `deploy-to-vms.sh` script to simplify the deployment process.

### Jeffrey
- https://github.com/doda2025-team14/operation/pull/97

Finalised the rate limiting pull request

### Alessandro

- https://github.com/doda2025-team14/model-service/pull/25

The update of `version.txt` wasn't working correctly because the `Dockerfile` wasn't using the new `build-arg` passed from the workflow.

- https://github.com/doda2025-team14/app/pull/25
- https://github.com/doda2025-team14/operation/pull/121

Centralized everything into an .env for application level variables and in values.yml for playbook related parameters. Removed Dockerfile.local as it was dead code.

- https://github.com/doda2025-team14/operation/pull/115

Added self-signed TLS certificates to the NGINX ingress.

## Week 9

### Boris


### Elvira
LINK

TEXT

### Conall
LINK

TEXT

### Wilhelm
- https://github.com/doda2025-team14/operation/pull/128
- https://github.com/doda2025-team14/operation/pull/133

Fixed bug involving ingress incorrectly routing traffic to canary deployment, added screenshots of visualisation to `continuous-experimentation.md`, worked on slides for the final presentation.

### Jeffrey
LINK

TEXT

### Alessandro
- https://github.com/doda2025-team14/operation/pull/126

Added deployment documentation.
