data "template_file" "anthos_deploy_cluster_script" {
    template = "${file("anthos/deploy_clusters.py")}"
    vars = { 
        private_subnets = "${jsonencode(var.private_subnets)}"
        vsphere_network = "${var.anthos_deploy_network}"
        create_anthos_cluster = "${var.anthos_deploy_clusters}"
    }
}

data "template_file" "anthos_tf_deploy_cluster" {
    template = "${file("anthos/cluster_tf.sh")}"
    vars = { 
        anthos_deploy_clusters = "${var.anthos_deploy_clusters}"
    }
}

data "template_file" "anthos_finish_cluster" {
    template = "${file("anthos/cluster/finish_cluster.sh")}"
    vars = {
        anthos_user_cluster_name = "${var.anthos_user_cluster_name}"
	ksa_token_path = "/home/ubuntu/cluster/ksa_token.txt"
    }
}

data "template_file" "anthos_cluster_config" {
    template = "${file("anthos/cluster/bundled-lb-admin-uc1-config.yaml")}"
    vars = { 
        vcenter_user = "Administrator@vsphere.local"
        vcenter_pass = "${random_string.sso_password.result}"
        vcenter_fqdn = "${format("vcva.%s", var.domain_name)}"
        vcenter_datastore = "vsanDatastore"
        vcenter_datacenter = "${var.vcenter_datacenter_name}"
        vcenter_cluster = "${var.vcenter_cluster_name}"
        resource_pool = "${var.anthos_resource_pool_name}"
        deploy_network = "${var.anthos_deploy_network}"
        anthos_version = "${var.anthos_version}"
        admin_service_cidr = "${var.anthos_admin_service_cidr}"
        admin_pod_cidr = "${var.anthos_admin_pod_cidr}"
        user_cluster_name = "${var.anthos_user_cluster_name}"
        user_service_cidr = "${var.anthos_user_service_cidr}"
        user_pod_cidr = "${var.anthos_user_pod_cidr}"
        gcp_project_id = "${var.anthos_gcp_project_id}"
        gcp_region = "${var.anthos_gcp_region}"
	anthos_user_master_replicas = "${var.anthos_user_master_replicas}"
	anthos_user_worker_replicas = "${var.anthos_user_worker_replicas}"
	anthos_user_vcpu = "${var.anthos_user_vcpu}"
	anthos_user_memory_mb = "${var.anthos_user_memory_mb}"
	whitelisted_key_name = "${var.whitelisted_key_name}"
	connect_key_name = "${var.connect_key_name}"
	register_key_name = "${var.register_key_name}"
	stackdriver_key_name = "${var.stackdriver_key_name}"
    }   
}

data "template_file" "anthos_cluster_creation_script" {
    template = "${file("anthos/cluster/bundled-lb-install-script.sh")}"
    vars = { 
        vcenter_user = "Administrator@vsphere.local"
        vcenter_pass = "${random_string.sso_password.result}"
        vcenter_fqdn = "${format("vcva.%s", var.domain_name)}"
        vcenter_datastore = "vsanDatastore"
        vcenter_datacenter = "${var.vcenter_datacenter_name}"
	whitelisted_key_name = "${var.whitelisted_key_name}"
	anthos_user_cluster_name = "${var.anthos_user_cluster_name}"
    }
}

resource "null_resource" "anthos_deploy_cluster" { 
    depends_on = [null_resource.anthos_deploy_workstation] 
    connection { 
        type = "ssh" 
        user = "root" 
        private_key = "${file("~/.ssh/id_rsa")}" 
        host = "${packet_device.router.access_public_ipv4}" 
    } 
 
    provisioner "file" { 
        content = "${data.template_file.anthos_deploy_cluster_script.rendered}" 
        destination = "/root/anthos/deploy_clusters.py" 
    }

    provisioner "file" { 
        content = "${data.template_file.anthos_tf_deploy_cluster.rendered}" 
        destination = "/root/anthos/cluster_tf.sh"
    }
 
    provisioner "file" { 
        content = "${data.template_file.anthos_cluster_config.rendered}" 
        destination = "/root/anthos/cluster/bundled-lb-admin-uc1-config.yaml" 
    } 
 
    provisioner "file" { 
        content = "${data.template_file.anthos_cluster_creation_script.rendered}"
        destination = "/root/anthos/cluster/bundled-lb-install-script.sh" 
    } 
    
    provisioner "file" { 
        source = "anthos/cluster/admin-lb-ipblock.yaml"
        destination = "/root/anthos/cluster/admin-lb-ipblock.yaml" 
    } 
    
    provisioner "file" { 
        source = "anthos/cluster/usercluster-1-lb-ipblock.yaml"
        destination = "/root/anthos/cluster/usercluster-1-lb-ipblock.yaml" 
    } 
    
    provisioner "file" { 
        source = "anthos/cluster/deploy_cluster.tf.tpl"
        destination = "/root/anthos/cluster/deploy_cluster.tf"
    }
    provisioner "file" {
        content = "${data.template_file.anthos_finish_cluster.rendered}"
        destination = "/root/anthos/cluster/finish_cluster.sh"
    }
    provisioner "remote-exec" { 
        inline = [ 
            "cp /root/anthos/gcp_keys/* /root/anthos/cluster/", 
            "python3 /root/anthos/deploy_clusters.py",
            "bash /root/anthos/cluster_tf.sh"
        ] 
    } 
}
 
