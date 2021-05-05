[![Equinix Metal Website](https://img.shields.io/badge/Website%3A-metal.equinix.com-blue)](http://metal.equinix.com) [![Slack Status](https://slack.equinixmetal.com/badge.svg)](https://slack.equinixmetal.com/) [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com) ![](https://img.shields.io/badge/Stability-Experimental-red.svg)

# Automated Anthos Installation via Terraform for Equinix Metal
These files will allow you to use [Terraform](http://terraform.io) to deploy [Google Cloud's Anthos GKE on-prem](https://cloud.google.com/anthos) on VMware vSphere on [Equinix Metal's Bare Metal Cloud offering](http://metal.equinix.com). 

Terraform will create a Equinix Metal project complete with a linux machine for routing, a vSphere cluster installed on minimum 3 ESXi hosts with vSAN storage, and an Anthos GKE on-prem admin and user cluster registered to Google Cloud. You can use an existing Equinix Metal Project, check this [section](#use-an-existing-equinix-metal-project) for instructions.

![Environment Diagram](docs/images/google-anthos-vsphere-network-diagram-1.png)

Users are responsible for providing their own VMware software, Equinix Metal account, and Anthos subscription as described in this readme.

The build (with default settings) typically takes 70-75 minutes.

**This repo is by no means meant for production purposes**, a production cluster is possible, but needs some modifications. If your desire is to create a production deployment, please consult with Equinix Metal Support via a support ticket.

## Join us on Slack
We use [Slack](https://slack.com/) as our primary communication tool for collaboration. You can join the Equinix Metal Community Slack group by going to [slack.equinixmetal.com](https://slack.equinixmetal.com/) and submitting your email address. You will receive a message with an invite link. Once you enter the Slack group, join the **#google-anthos** channel! Feel free to introduce yourself there, but know it's not mandatory.

## Latest Updates

Starting with version v0.2.0, this module is published in the Terraform registy at <https://registry.terraform.io/modules/equinix/anthos-on-vsphere/metal/latest>.

For current releases, with Git tags, see <https://github.com/packet-labs/google-anthos/releases>.
Historic changes are listed here by date.

### 9-25-2020
* GKE on-prem 1.5.0-gke.27 has been released and has been successfully tested
### 7-29-2020
* Several terraform formating and normailziaion with packet-labs github has been performed
* GKE on-prem 1.4.1-gke.1 patch release has been successfully tested
### 6-25-2020
* Support for GKE on-prem 1.4 added
### 6-8-2020
* Added a `check_capacity.py` to manually perform a capacity check with Equinix Metal before building
### 6-03-2020
* 1.3.2-gke.1 patch release has been successfully tested
* Option to use Equinix Metal gen 3 (c3.medium.x86 for esxi and c3.small.x86 for router) along with ESXi 6.7
### 5-04-2020
* 1.3.1-gke.0 patch release has been successfully tested
### 3-31-2020
* The terraform is fully upgraded to work with Anthos GKE on-prem version
1.3.0-gke.16
* There is now an option to use an existing Equinix Metal project rather than create a
  new one (default behavior is to create a new project)
* We no longer require a private .ssh key for the environment be saved at
  ~/.ssh/id_rsa. The terraform will generate a ssh key pair and save it to
  ~/.ssh/<project_name>-<timestamp>. A .bak of the same file name is also
  created so that the key will be available after a `terraform destroy` command.

## Prerequisites
To use these Terraform files, you need to have the following Prerequisites:
* An [Anthos subscription](https://cloud.google.com/anthos/docs/getting-started)
* A [white listed GCP project and service account](https://cloud.google.com/anthos/gke/docs/on-prem/how-to/gcp-project).
* A Equinix Metal org-id and [API key](https://www.packet.com/developers/api/)
* **If you are new to Equinix Metal**
  * You will need to request an "Entitlement Increase".  You will need to work with Equinix Metal Support via either:
    * Use the ![Equinix Metal Website](https://img.shields.io/badge/Chat%20Now%20%28%3F%29-blue) at the bottom left of the Equinix Metal Web UI
      * OR
    * E-Mail support@equinixmetal.com
  * Your message across one of these mediums should be:
    * I am working with the Google Anthos Terrafom deployment (github.com/equinix/terraform-metal-anthos-on-vsphere). I need an entitlement increase to allow the creation of five or more vLans. Can you please assist?
* [VMware vCenter Server 6.7U3](https://my.vmware.com/group/vmware/details?downloadGroup=VC67U3B&productId=742&rPId=40665) - VMware vCenter Server Appliance ISO obtained from VMware
* [VMware vSAN Management SDK 6.7U3](https://my.vmware.com/group/vmware/details?downloadGroup=VSAN-MGMT-SDK67U3&productId=734) - Virtual SAN Management SDK for Python, also from VMware
 
## Associated Equinix Metal Costs
The default variables make use of 4 [c2.medium.x86](https://metal.equinix.com/product/servers/) servers. These servers are $1 per hour list price (resulting in a total solution price of roughly $4 per hour). Additionally, if you would like to use Intel Processors for ESXi hosts, the [m2.xlarge.x86](https://metal.equinix.com/product/servers/) is a validated configuration. This would increase the useable RAM from 192GB to a whopping 1.15TB. These servers are $2 per hour list price (resulting in a total solution price of roughly $7 per hour.)

You can also deploy just 2 [c2.medium.x86](https://metal.equinix.com/product/servers/) servers for $2 per hour instead.

## Tested GKE on-prem versions
The Terraform has been successfully tested with following versions of GKE on-prem:
* 1.1.2-gke.0*
* 1.2.0-gke.6*
* 1.2.1-gke.4*
* 1.2.2-gke.2*
* 1.3.0-gke.16
* 1.3.1-gke.0
* 1.3.2-gke.1
* 1.4.0-gke.13
* 1.4.1-gke.1
* 1.5.0-gke.27

To simplify setup, this is designed to used the bundled Seesaw load balancer. No other load balancer support is planned at this time.

Select the version of Anthos you wish to install by setting the `anthos_version` variable in your terraform.tfvars file. 

\*Due to a known bug in the BundledLb EAP version, the script will automatically detect when using the EAP version and automatically delete the secondary LB in each group (admin and user cluster) to prevent the bug from occurring.

## Setup your GCS object store 
You will need a GCS  object store in order to download *closed source* packages such as *vCenter* and the *vSan SDK*. (See below for an S3 compatible object store option)

The setup will use a service account with Storage Admin permissions to download the needed files. You can create this service account on your own or use the helper script described below.

You will need to layout the GCS structure to look like this:

```
https://storage.googleapis.com:
    |
    |__ bucket_name/folder/
        |
        |__ VMware-VCSA-all-6.7.0-14367737.iso
        |
        |__ vsanapiutils.py
        |
        |__ vsanmgmtObjects.py
```
Your VMware ISO name may vary depending on which build you download.
These files can be downloaded from [My VMware](http://my.vmware.com).
Once logged in to "My VMware" the download links are as follows:
* [VMware vCenter Server 6.7U3](https://my.vmware.com/group/vmware/details?downloadGroup=VC67U3B&productId=742&rPId=40665) - VMware vCenter Server Appliance ISO
* [VMware vSAN Management SDK 6.7U3](https://my.vmware.com/group/vmware/details?downloadGroup=VSAN-MGMT-SDK67U3&productId=734) - Virtual SAN Management SDK for Python

You will need to find the two individual Python files in the vSAN SDK zip file and place them in the GCS bucket as shown above.
 
 
## Download/Create your GCP Keys for your service accounts and activate APIs for your project
The GKE on-prem install requires several service accounts and keys to be created. See the [Google documentation](https://cloud.google.com/gke-on-prem/docs/how-to/service-accounts) for more details. You can create these keys manually, or use a provided helper script to make the keys for you.

The Terraform files expect the keys to use the following naming convention, matching that of the Google documentation:
* register-key.json
* connect-key.json
* stackdriver-key.json
* whitelisted-key.json

If doing so manually, you must create each of these keys and place it in a folder named `gcp_keys` within the `anthos` folder. 
The service accounts also need to have IAM roles assigned to each of them. To do this manually, you'll need to follow the [instructions from Google](https://cloud.google.com/gke-on-prem/docs/how-to/service-accounts#assign_roles)


GKE on-prem also requires [several APIs](https://cloud.google.com/gke-on-prem/docs/how-to/gcp-project#enable_apis) to be activated on your target project.

Much easier (and recommended) is to use the helper script located in the `anthos` directory called `create_service_accounts.sh` to create these keys, assign the IAM roles, and activate the APIs. The script will allow you to log into GCP with your user account and select your Anthos white listed project. You'll also have an option to create a GCP service account to read from the GCS bucket. If you choose this option, you will create a `storage-reader-key.json`.

 
You can run this script as follows: 

`anthos/create_service_accounts.sh`

Prompts will guide you through the setup. 
 
## Install Terraform 
Terraform is just a single binary.  Visit their [download page](https://www.terraform.io/downloads.html), choose your operating system, make the binary executable, and move it into your path. 
 
Here is an example for **macOS**: 
```bash 
curl -LO https://releases.hashicorp.com/terraform/0.12.18/terraform_0.12.18_darwin_amd64.zip 
unzip terraform_0.12.18_darwin_amd64.zip 
chmod +x terraform 
sudo mv terraform /usr/local/bin/ 
``` 
 
## Download this project
To download this project, run the following command:

```bash
git clone https://github.com/equinix/terraform-metal-anthos-on-vsphere.git
```

## Initialize Terraform 

Terraform uses modules to deploy infrastructure. In order to initialize the modules your simply run: `terraform init -upgrade`. This should download five modules into a hidden directory `.terraform`.

## Modify your variables 
There are many variables which can be set to customize your install within `00-vars.tf` and `30-anthos-vars.tf`. The default variables to bring up a 3 node vSphere cluster and linux router using Equinix Metal's [c2.medium.x86](https://metal.equinix.com/product/servers/). Change each default variable at your own risk. 

There are some variables you must set with a terraform.tfvars files. You need to set `auth_token` & `organization_id` to connect to Equinix Metal and the `project_name` which will be created in Equinix Metal. You will need to set `anthos_gcp_project_id` for your GCP Project ID. You will need a GCS bucket to download "Closed Source" packages such as vCenter. You need to provide the vCenter ISO file name as `vcenter_iso_name`.

The Anthos variables include `anthos_version` and `anthos_user_cluster_name`.
 
Here is a quick command plus sample values to start file for you (make sure you adjust the variables to match your environment, pay special attention that the `vcenter_iso_name` matches whats in your bucket): 
```bash 
cat <<EOF >terraform.tfvars 
auth_token = "cefa5c94-e8ee-4577-bff8-1d1edca93ed8" 
organization_id = "42259e34-d300-48b3-b3e1-d5165cd14169" 
project_name = "anthos-packet-project-1"
anthos_gcp_project_id = "my-anthos-project" 
vcenter_iso_name = "VMware-VCSA-all-6.7.0-XXXXXXX.iso" 
anthos_version = "1.3.0-gke.16"
anthos_user_cluster_name = "packet-cluster-1"
EOF
``` 

## Using an S3 compatible object store (optional)


You have the option to use an S3 compatible object store in place of GCS in order to download *closed source* packages such as *vCenter* and the *vSan SDK*. [Minio](http://minio.io) an open source object store, works great for this.

You will need to layout the S3 structure to look like this:
``` 
https://s3.example.com: 
    | 
    |__ vmware 
        | 
        |__ VMware-VCSA-all-6.7.0-14367737.iso
        | 
        |__ vsanapiutils.py
        | 
        |__ vsanmgmtObjects.py
``` 
These files can be downloaded from [My VMware](http://my.vmware.com).
Once logged in to "My VMware" the download links are as follows:
* [VMware vCenter Server 6.7U3](https://my.vmware.com/group/vmware/details?downloadGroup=VC67U3B&productId=742&rPId=40665) - VMware vCenter Server Appliance ISO
* [VMware vSAN Management SDK 6.7U3](https://my.vmware.com/group/vmware/details?downloadGroup=VSAN-MGMT-SDK67U3&productId=734) - Virtual SAN Management SDK for Python
 
You will need to find the two individual Python files in the vSAN SDK zip file and place them in the S3 bucket as shown above.

For the cluster build to use the S3 option you'll need to change your variable file by setting `object_storage_tool` to `mc` and including the `s3_url`, `object_store_bucket_name`, `s3_access_key`, `s3_secret_key` in place of the gcs variables.

Here is the create variable file command again, modified for S3:
```bash 
cat <<EOF >terraform.tfvars 
auth_token = "cefa5c94-e8ee-4577-bff8-1d1edca93ed8" 
organization_id = "42259e34-d300-48b3-b3e1-d5165cd14169" 
project_name = "anthos-packet-project-1"
anthos_gcp_project_id = "my-anthos-project" 
object_store_tool = "mc"
s3_url = "https://s3.example.com" 
object_store_bucket_name = "vmware"
s3_access_key = "4fa85962-975f-4650-b603-17f1cb9dee10" 
s3_secret_key = "becf3868-3f07-4dbb-a6d5-eacfd7512b09" 
vcenter_iso_name = "VMware-VCSA-all-6.7.0-XXXXXXX.iso" 
anthos_version = "1.5.0-gke.27"
anthos_user_cluster_name = "packet-cluster-1"
EOF 
```  
 
## Deploy the Equinix Metal vSphere cluster and Anthos GKE on-prem cluster 
 
All there is left to do now is to deploy the cluster: 
```bash 
terraform apply --auto-approve 
``` 
This should end with output similar to this: 
``` 
Apply complete! Resources: 50 added, 0 changed, 0 destroyed. 
 
Outputs: 

KSA_Token_Location = The user cluster KSA Token (for logging in from GCP) is located at ./ksa_token.txt
SSH_Key_Location = An SSH Key was created for this environment, it is saved at ~/.ssh/project_2-20200331215342-key
VPN_Endpoint = 139.178.85.91
VPN_PSK = @1!64v7$PLuIIir9TPIJ
VPN_Password = n3$xi@S*ZFgUbB5k
VPN_User = vm_admin
vCenter_Appliance_Root_Password = *XjryDXx*P8Y3c1$
vCenter_FQDN = vcva.packet.local
vCenter_Password = 3@Uj7sor7v3I!4eo
```

The above Outputs will be used later for setting up the VPN.
You can copy/paste them to a file now,
or get the values later from the file `terraform.tfstate`
which should have been automatically generated as a side-effect of the "terraform apply" command.

## Checking Capacity in a Equinix Metal Facility (optional)
Before attempting to create the cluster, it is a good idea to do a quick capacity check to be sure there are enough devices at your chosen Equinix Metal facility.

We've included a `check_capacity.py` file to be run prior to a build. The file will read your `terraform.tfvars` file to use your selected host sizes and quantities or use the defaults if you've not set any.

Running the `check_capacity.py` file requires that you have python3 installed on your system.

Running the test is done with a simple command:
```bash
python3 check_capacity.py
```

The output will confirm which values it checked capacity for and display the results:
```
Using the default value for facility: dfw2
Using the default value for router_size: c2.medium.x86
Using the user variable for esxi_size: c3.medium.x86
Using the user variable for esxi_host_count: 3



Is there 1 c2.medium.x86 instance available for the router in dfw2?
Yes

Are there 3 c3.medium.x86 instances available for ESXi in dfw2?
Yes
```

## Size of the vSphere Cluster
The code supports deploying a single ESXi server or a 3+ node vSAN cluster. Default settings are for 3 ESXi nodes with vSAN.

When a single ESXi server is deployed, the datastore is extended to use all available disks on the server. The linux router is still deployed as a separate system.

To do a single ESXi server deployment, set the following variables in your `terraform.tfvars` file:

```bash
esxi_host_count             = 1
anthos_datastore            = "datastore1"
anthos_user_master_replicas = 1
```
This has been tested with the c2.medium.x86. It may work with other systems as well, but it has not been fully tested.
We have not tested the maximum vSAN cluster size. Cluster size of 2 is not supported.

## Using Equinix Metal Gen 3 Hardware and ESXi 6.7
Equinix Metal is actively rolling out new hardware in mulitple locations which supports ESXi 6.7. Until the gen 3 hardware is more widely available, we'll not make gen 3 hardware the default but provide the option to use it.

### Costs
The gen3 [c3.medium.x86](https://metal.equinix.com/product/servers/) is $0.10 more than the [c2.medium.x86](https://metal.equinix.com/product/servers/) but benefits from higher clock speed and the storage is better utlized to create a larger vSAN data store.

The [c3.small.x86](https://metal.equinix.com/product/servers/) is $0.50 less expensive than the [c2.medium.x86](https://metal.equinix.com/product/servers/). Therefore in a standard build, with 3 ESXi servers and 1 router, the net costs should be $0.20 lower than when using gen 2 devices.

### Known Issues
ESXi 6.7 deployed on [c3.medium.x86](https://metal.equinix.com/product/servers/) may result in an alarm in vCenter which states `Host TPM attestation alarm`. The Equinix Metal team is looking into this but its thought to be a cosemetic issue.

Upon using `terraform destroy --auto-approve` to clean up an install, the VLANs may not get cleaned up properly.

### Instructions to use gen 3
Using gen 3 requires modifying the `terraform.tfvars` file to include a few new variables:
```bash
esxi_size      = "c3.medium.x86"
vmware_os      = "vmware_esxi_6_7"
router_size    = "c3.small.x86"
```
These simple additions will cause the script to use the gen 3 hardware.

## Connect to the Environment via VPN
By connecting via VPN, you will be able to access vCenter plus the admin workstation, cluster VMs, and any services exposed via the seesaw load balancers.

There is an L2TP IPsec VPN setup. There is an L2TP IPsec VPN client for every platform. You'll need to reference your operating system's documentation on how to connect to an L2TP IPsec VPN. 

[MAC how to configure L2TP IPsec VPN](https://support.apple.com/guide/mac-help/set-up-a-vpn-connection-on-mac-mchlp2963/mac)

NOTE- On a mac, for manual VPN setup use the values from Outputs (or from the generated file `terraform.tfstate`):
* "Server Address" = `VPN_Endpoint`
* "Account Name" = `VPN_User`
* "User Authentication: Password" = `VPN_Password`
* "Machine Authentication: Shared Secret" = `VPN_PSK`

[Chromebook how to configure LT2P IPsec VPN](https://support.google.com/chromebook/answer/1282338?hl=en)

Make sure to enable all traffic to use the VPN (aka do not enable split tunneling) on your L2TP client.
NOTE- On a mac, this option is under the "Advanced..." dialog when your VPN is selected (under System Preferences > Network Settings).

Some corporate networks block outbound L2TP traffic. If you are experiencing issues connecting, you may try a guest network or personal hotspot.

Windows 10 is known to be very finicky with L2TP Ipsec VPN. If you are on a Windows 10 client and experience issues getting VPN to work, consider using OpenVPN instead. These [instructions](https://www.cyberciti.biz/faq/ubuntu-18-04-lts-set-up-openvpn-server-in-5-minutes/) may help setting up OpenVPN on the edge-gateway. 

## Connect to the clusters
You will need to ssh into the router/gateway and from there ssh into the admin workstation where the kubeconfig files of your clusters are located. NOTE- This can be done with or without establishing the VPN first.

```
ssh -i ~/.ssh/<private-ssh-key-created-by-project> root@VPN_Endpoint
ssh -i /root/anthos/ssh_key ubuntu@admin-workstation
```

The kubeconfig files for the admin and user clusters are located under ~/cluster, you can for example check the nodes of the admin cluster with the following command

```
kubectl --kubeconfig ~/cluster/kubeconfig get nodes
```

## Connect to the vCenter
Connecting to the vCenter requires that the VPN be established. Once the VPN is connected, launch a browser to https://vcva.packet.local/ui.
You’ll need to accept the self-signed certificate, and then enter the
`vCenter_Username` and `vCenter_Password`
provided in the Outputs of the run of "terraform apply"
(or alternatively from the generated file `terraform.tfstate`).
NOTE- use the `vCenter_Password` and not the `vCenter_Appliance_Root_Password`.
NOTE- on a mac, you may find that the chrome browser will not allow the connection.
If so, try using firefox.

## Exposing k8s services
Currently services can be exposed on the bundled seesaw load balancer(s) on VIPs
within the VM Private Network (172.16.3.0/24 by default). By default we exclude
the last 98 usable IPs of the 172.16.3.0/24 subnet from the DHCP range--
172.16.3.156-172.16.3.254. You can
change this number by adjusting the `reserved_ip_count` field in the VM Private
Network json in `00-vars.tf`. 

At this point services are not exposed to the public internet--you must connect via VPN to access the VIPs and services. One could adjust
iptables on the edge-gateway to forward ports/IPs to VIP.

## Cleaning the environment
To clean up a created environment (or a failed one), run `terraform destroy --auto-approve`.

If this does not work for some reason, you can manually delete each of the resources created in Equinix Metal (including the project) and then delete your terraform state file, `rm -f terraform.tfstate`.

## Skipping the Anthos GKE on-prem cluster creation steps
If you wish to create the environment (including deploy the admin workstation and Anthos pre-res) but skip the cluster creation (so that you can practice creating a cluster on your own) add `anthos_deploy_clusters = "False"` to your terraform.tfvars file. This will still run the pre-requisites for the GKE on-prem install including setting up the admin workstation.

To create just the vSphere environment and skip all Anthos related steps, add `anthos_deploy_workstation_prereqs = false`.

> Note that `anthos_deploy_clusters` uses a string of either `"True"` or `"False"` while  `anthos_deploy_workstation_prereqs` uses a boolean of `true` or `false`. This is because the `anthos_deploy_clusters` variable is used within a bash script while `anthos_deploy_workstation_prereqs` is used by Terraform which supports booleans.

See [anthos/cluster/bundled-lb-admin-uc1-config.yaml.sample](https://github.com/equinix/terraform-metal-anthos-on-vsphere/blob/master/anthos/cluster/bundled-lb-admin-uc1-config.yaml.sample) to see what the Anthos parameters are when the default settings are used to create the environment.

## Use an existing Equinix Metal project
If you have an existing Equinix Metal project you can use it assuming the project has at least 5 available vlans, Equinix Metal project has a limit of 12 Vlans and this setup uses 5 of them.

Get your Project ID, navigate to the Project from the console.equinixmetal.com console and click on PROJECT SETTINGS, copy the PROJECT ID.

add the following variables to your terraform.tfvars

```
create_project                    = false
project_id                        = "YOUR-PROJECT-ID"
```

## Changing default Anthos GKE on-prem cluster defaults
Check the `30-anthos-vars.tf` file for additional values (including number of user worker nodes and vCPU/RAM settings for the worker nodes) which can be set via the terraform.tfvars file.

## Google Anthos Documentation
Once Anthos is deployed on Equinix Metal, all of the documentation for using Google Anthos is located on the [Anthos Documentation Page](https://cloud.google.com/anthos/docs).

## Troubleshooting
Some common issues and fixes.

### Error: The specified project contains insufficient public IPv4 space to complete the request. Please e-mail help@packet.com.

Should be resolved in https://github.com/equinix/terraform-metal-anthos-on-vsphere/commit/f6668b1359683eb5124d6ab66457f3680072651a

Due to recent changes to the Equinix Metal API, new organizations may be unable to use the Terraform to build ESXi servers. Equinix Metal is aware of the issue and is planning some fixes. In the meantime, if you hit this issue, email help@equinixmetal.com and request that your organization be white listed to deploy ESXi servers with the API. You should reference this project (https://github.com/equinix/terraform-metal-anthos-on-vsphere) in your email.

### Error: POST https://api.packet.net/ports/e2385919-fd4c-410d-b71c-568d7a517896/disbond:

At times the Equinix Metal API fails to recognize the ESXi host can be enabled for Layer 2 networking (more accurately Mixed/hybrid mode). The terraform will exit and you'll see
```bash
Error: POST https://api.packet.net/ports/e2385919-fd4c-410d-b71c-568d7a517896/disbond: 422 This device is not enabled for Layer 2. Please contact support for more details. 

  on 04-esx-hosts.tf line 1, in resource "packet_device" "esxi_hosts":
   1: resource "packet_device" "esxi_hosts" {
```

If this happens, you can issue `terraform apply --auto-approve` again and the problematic ESXi host(s) should be deleted and recreated again properly. Or you can perform `terraform destroy --auto-approve` and start over again.

### null_resource.download_vcenter_iso (remote-exec): E: Could not get lock /var/lib/dpkg/lock - open (11: Resource temporarily unavailable)

Occasionally the Ubuntu automatic unattended upgrades will run at an unfortunate time and lock apt while the script is attempting to run. 

Should this happen, the best resolution is to clean up your deployment and try again. 

### SSH_AUTH_SOCK: dial unix /tmp/ssh-vPixj98asT/agent.11502: connect: no such file or directory

A failed deployment which results in the following output:
```bash
Error: Error connecting to SSH_AUTH_SOCK: dial unix /tmp/ssh-vPixj98asT/agent.11502: connect: no such file or directory



Error: Error connecting to SSH_AUTH_SOCK: dial unix /tmp/ssh-vPixj98asT/agent.11502: connect: no such file or directory



Error: Error connecting to SSH_AUTH_SOCK: dial unix /tmp/ssh-vPixj98asT/agent.11502: connect: no such file or directory



Error: Error connecting to SSH_AUTH_SOCK: dial unix /tmp/ssh-vPixj98asT/agent.11502: connect: no such file or directory
```

This could be because you are using a terminal emulation such as `screen`or `tmux` and the SSH agent is not running. May be corrected by running the command `ssh-agents bash` prior to running the `terraform apply --auto-approve` command.

