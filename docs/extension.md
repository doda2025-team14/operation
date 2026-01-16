# Extension Proposal: Declarative Provisioning

## Motivation
Infrastructure as Code (IaC) is considered an important aspect of release engineering for acheiving consistent and reproducible deployments. Our project uses IaC throughout, ranging from specifying Kubernetes manifests and Helm charts, to defining release workflows and provisioning VMs with Vagrant and Ansible. Among these tools, Ansible is the only one that follows an imperative IoC approach, which is inconsistent with the declarative nature of the rest of our infrastructure. Imperative IaC, in general, tends to be less predictible and more error prone than declarative approaches, since changes are applied sequentially rather than defined in terms of a desired end state [[1]][imp-vs-dec-iac].

A recurring pain point throughout the development process was extending the Ansible playbooks to configure additional software and environment variables on the provisioned VMs. Incrementally updating the playbooks proved to be a slow and tedious process, as adding a new feature required sitting through the provisioning process, up to five minutes, to reach a state from which development could begin. Furthermore, Ansible does not update the VMs in an atomic way, meaning that when a playbook failed midway, the VM was left in an inconsistent, partially configured state. Since there is no rollback mechanism, recovering from such a situation often required deleting the VM and starting over which wasted time and disrupted development workflows. Moreover, Ansible does not provide true reproducibility due to its imperative nature; it attempts to converge on a desired state but does not actually guarantee congruence [[2]][ansible-convergance]. Collectively, these limitations make developing, maintaining, and iterating on Ansible playbooks cumbersome, time-consuming, and prone to human error.



## Proposed Solution: NixOS
To address these shortcomings, we propose replacing the Ubuntu VMs and Ansible playbooks with NixOS VMs and a declarative Nix configuration. NixOS is a Linux distribution built on the Nix package manager which takes a purely functional and declarative approach to system configuration [[3]]. All system details, including permissions, network settings, packages and program configuration, can be declared and applied all at once without needing to worry about the exact order of steps required to achieve the desired state. This provides a layer of abstraction for the entire provisioning process with stronger guarantees about correctness and reproducibility.

Furthermore, NixOS is an immutable operating system meaning that changes to the system configuration do not mutate the existing state but instead produces a new snapshot of the system called a generation. This process is entirely atomic: either Nix can successfully evaluate the configuration and apply it immediately, or evaluation fails and the system remains in the previous working version. Consequently, the problem of Ansible sometimes producing a partially configured VM is no longer a concern. Each system generation is also saved which provides an efficient rollback mechanism.



## Refactoring Strategy
We present a list of tasks required to switch from Ansible to NixOS

**Task 1: Setup Nix Flake Structure:** Create a `flake.nix` file at the root of the `operation` repository. This file will define the inputs (NixOS version and other dependencies) and outputs (the NixOS configurations for the control plane and worker nodes). Flakes provide a standardised way to manage Nix projects and ensure reproducibility by pinning all dependencies and their version information in a `flake.lock` file.

**Task 2: Create NixOS Modules for Control Plane and Worker Nodes:** Create two files `ctrl.nix` and `node.nix` which will contain the declarative configuration for each type of node.

**Task 3: Translate Playbook Logic into Nix:** The configuration required for each node type in the cluster is specified in steps 1-17 as described in [A2: Provisioning a Kubernetes Cluster](https://brightspace.tudelft.nl/d2l/le/content/774572/viewContent/4646349/View). These steps need to be performed in the the Nix configuration language rather than sequenced Linux commands in an Ansible playbook. Tools such as [MyNixOS](https://mynixos.com/) can be used to look up individual packages and options available in NixOS. For example, installing software or tools requires adding them to the `environment.systemPackages` list in the NixOS configuration.

**Task 4: Update Vagrantfile:** Modify the `Vagrantfile` to use a generic NixOS base box instead of the current Ubuntu box. The provisioning step also needs to be updated to apply the NixOS configuration by running the following command:
```
nixos-rebuild switch --flake .#<hostname>
```
where <hostname> is either `ctrl` or `node-1`, `node-2`, etc



## Expected Outcome and Evaluation

design experiment here


## Assumptions and Potential Drawbacks
NixOS is considered hard and complicated
Hard if software/tool not already packaged


## Sources
[imp-vs-dec-iac]: https://www.graphapp.ai/blog/declarative-vs-imperative-iac-understanding-the-key-differences
[1]: Davis, Tyler. (2025). [*Declarative vs Imperative IaC: Understanding the Key Differences*](https://www.graphapp.ai/blog/declarative-vs-imperative-iac-understanding-the-key-differences). Graph.

[ansible-convergance]: https://flyingcircus.io/en/about-us/blog-news/details-view/thoughts-on-systems-management-methods
[2]: Kauhaus, Christian. (2016). [*Thoughts on Systems Management Methods*](https://flyingcircus.io/en/about-us/blog-news/details-view/thoughts-on-systems-management-methods). Flying Circus.

[nixos-paper]: https://edolstra.github.io/pubs/nixos-jfp-final.pdf
[3]: Dolstra, Eelco and Löh, Andres and Pierron, Nicolas (2016). [*NixOS: A Purely Functional Linux Distribution*](https://edolstra.github.io/pubs/nixos-jfp-final.pdf).

NixOS VS Ansible: https://discourse.nixos.org/t/nixos-vs-ansible/16757


Extension Proposal: Critically reflect on the current state of your project and identify one release-engineering- related shortcoming of the project practices that you find the most critical, annoying, or error prone. It must be related to an assignment, e.g., the training or release pipelines, contribution process, deployment, or experimentation. Document the identified shortcoming and describe its effect, a convincing argumentation is crucial.

Describe and visualize a project refactoring/extension that would improve the situation. The proposed change should be non-trivial, but also implementable, aim for 1-5 days of effort. Be concrete, you can take the perspective of having to implement the extension as the next assignment. From your description, the concrete tasks for implementing the proposed change in your project are clear. Describe the expected outcome of your change (e.g., how does your project/process improve?) and explain how you could test whether the changed design has the desired effect, i.e., how an experiment could be designed to measure the resulting effects. The extension proposal should also reflect on your underlying assumptions or possible downsides of the change. Link to information sources that provide additional information, inspiration for your solution, or concrete examples for its realization. We expect that you only cite respectable sources (e.g., research papers, quality blogs like Medium, tool websites, or popular StackOverflow discussions).

Do not just link tools, find a discussion or reflection on the technology or write one yourself. It should be clearly motivated and point to a concrete pain point. Just saying "We want to adopt XY" is not an argument.