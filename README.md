# Cilium Cluster Mesh Installation/Configuration With Ansible

[Cilium Cluster Mesh](https://cilium.io/use-cases/cluster-mesh/)  enables administrators to seamlessly interconnect multiple Kubernetes clusters into a unified mesh network, where pod networks across different clusters are fully integrated. This allows pods from one cluster to communicate with pods or Kubernetes services in another cluster using IP addresses or DNS names. This functionality is particularly beneficial in scenarios such as when an application is deployed in one Kubernetes cluster, but its database resides in another, or when an application is distributed across several clusters, and administrators need to balance traffic across all available pods using Kubernetes ingresses.

In my home lab Kubernetes clusters, I've been using Cilium CNI for an extended period, and I've recently implemented Cilium Cluster Mesh to facilitate the distribution of applications across my clusters. This setup allows me to move applications between clusters with minimal service disruption, which is especially useful during reinstallation, maintenance, or upgrades of any Kubernetes cluster.

I manage my Kubernetes clusters using a GitOps approach, utilizing ArgoCD to deploy and configure everything via ArgoCD ApplicationSets/Applications. I define the Git repository with Kubernetes manifests or Helm charts containing the necessary values to deploy an application, and I intend to apply the same methodology for deploying and configuring Cilium CNI and Cilium Mesh.

Previously, setting up Cilium Cluster Mesh involved several manual steps, such as creating and copying certificates required for establishing connections between clusters. However, starting with Cilium version 1.14.0, the Cilium Helm chart allows administrators to configure Cluster Mesh using the GitOps approach. By simply installing the Cilium Helm chart with the appropriate values, Cluster Mesh becomes operational immediately.

In this article, I will detail the steps to deploy and configure Kubernetes clusters interconnected with Cilium Cluster Mesh using the Cilium Helm Chart, version 1.16.1.

## Ansible

This repository contains Ansible playbooks and related configuration files to automate the deployment and management of Kubernetes clusters using RKE2 and Cilium. The setup is designed to configure multiple clusters, enable networking and storage, and integrate Cilium as the CNI for advanced networking capabilities, including the use of Cluster Mesh.

### Repository Structure

**Playbooks**
    - `01-cluster1.yaml`: Configuration specific to the first Kubernetes cluster.
    - `02-cluster2.yaml`: Configuration specific to the second Kubernetes cluster.
    - `03-cluster2.yaml`: Configuration specific to the third Kubernetes cluster.
    - `04-cluster2.yaml`: Configuration specific to the fourth Kubernetes cluster.

**Inventories**
    - `inventories/cluster1/`: Inventory files containing details of the first Kubernetes cluster.
    - `inventories/cluster2/`: Inventory files containing details of the second Kubernetes cluster.
    - `inventories/cluster3/`: Inventory files containing details of the third Kubernetes cluster.
    - `inventories/cluster4/`: Inventory files containing details of the fourth Kubernetes cluster.

**Configuration Files**
    - `ansible.cfg`: Configuration settings for Ansible execution.
    - `requirements.yml`: External roles and dependencies required for the playbooks.

**Templates**
    - `templates/rke2/server-config.yaml.j2:` Jinja2 template for RKE2 server configuration.
    - `templates/rke2/agent-config.yaml.j2`: Jinja2 template for RKE2 agent configuration.
    - `templates/cilium/cilium-values.yaml.j2`: Jinja2 template for Cilium Helm values.
    - `templates/cilium/rke2-cilium-helm-config.yaml.j2`: Jinja2 template for configuring Cilium Helm on RKE2.
    - `templates/metallb/metalb-config.yaml.j2`: Jinja2 template for configuring `IPAddressPool` and `L2Advertisement` for MetalLB

**Roles**
    - `roles/network`: Tasks and variables related to networking setup.
    - `roles/rke2`: Tasks and variables specific to RKE2 installation and configuration.
    - `roles/storage`: Tasks related to storage provisioning.
    - `roles/cilium`: Tasks and configuration for setting up Cilium as the CNI, including Cluster Mesh integration.
    - `roles/init`: Initial setup tasks such as basic system preparation.
    - `roles/kernel`: Kernel configuration tasks to support RKE2 and Cilium.

**Group Variables**
    - `inventories/<HOST>/group_vars/all.yaml`: Variables to apply to all hosts in the `<HOST>` group
    - `group_vars/all.yml`: Global variables that apply to all hosts in the inventory.

**Files**
    - `files/tmp/`: Temporary files and artifacts generated during the setup process, such as CA/key, tokens and kubeconfig files.

### Usage

#### Prerequisites

Ensure that the following prerequisites are met before running the playbooks:

    - Ansible installed on the control node.
    - Access to the target Kubernetes nodes (SSH key-based authentication recommended).
    - Required dependencies specified in requirements.yml are installed.

#### Deployment Steps

1. Clone the Repository:

    ```bash
    git clone https://github.com/mkm29/cilium-rke2-ansible
    cd cilium-rke2-ansible
    ```

2. Update Inventory Files
   1. For each cluster you would like to configure, modify the `inventories/<HOST>/hosts.yaml` files with the appropriate details of your Kubernetes clusters (such as IP addresses)
   2. Update the `inventories/<HOST>/group_vars/all.yaml` file to customize what options you wish to pass to the roles
3. Install Ansible Galaxy Collections

    ```bash
    ansible-galaxy install -r requirements.yml --force
    ```

4. Run the Playbooks:

    ```bash
    ansible-playbook -i inventory/cluster1/hosts.yaml playbooks/01-cluster1.yaml
    ansible-playbook -i inventory/cluster4/hosts.yaml playbooks/02-cluster2.yaml
    ansible-playbook -i inventory/cluster4/hosts.yaml playbooks/03-cluster3.yaml
    ansible-playbook -i inventory/cluster4/hosts.yaml playbooks/04-cluster4.yaml
    ```

4. **Monitor and Verify**: Monitor the output of the Ansible playbook for any errors. Upon successful completion, verify the setup by accessing the Kubernetes clusters and checking the status of RKE2 and Cilium.

#### Customization

You can customize the deployment by modifying the variables in the `group_vars/all.yml` file, overrides specified in each inventory file or the respective role variable files under `roles/*/vars/main.yml`.

#### Cilium Cluster Mesh Configuration

To enable Cluster Mesh between multiple Kubernetes clusters, ensure that the appropriate values are set in the [cilium-values.yaml.j2](./templates/cilium/cilium-values.yaml.j2) template. Here we use the `cilium` binary to install and configure Cilium Cluster Mesh, but you could also go the Helm method. 

## Kustomize

In order to fully test Cilium Cluster Mesh, I have created a few Kustomize resources. _TODO_

## License

This repository is licensed under the MIT License. See the LICENSE file for more information.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request if you have any improvements or bug fixes.

Acknowledgments
Special thanks to the contributors and the community for their support and guidance in developing this Ansible configuration.