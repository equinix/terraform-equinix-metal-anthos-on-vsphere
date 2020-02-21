variable "admin_workstation_ip" {
}

resource "null_resource" "anthos_deploy_cluster" { 
    connection { 
        type = "ssh" 
        user = "ubuntu" 
        private_key = "${file("/root/anthos/ssh_key")}" 
        host = "${var.admin_workstation_ip}" 
    }

    provisioner "file" {
        source      = "/root/anthos/cluster"
        destination = "/home/ubuntu"
    }

    provisioner "remote-exec" { 
        inline = [
            "cd /home/ubuntu/cluster/",
            "bash /home/ubuntu/cluster/bundled-lb-install-script.sh",
            "bash /home/ubuntu/cluster/finish_cluster.sh"
        ]   
    }  

}


resource "null_resource" "anthos_copy_token"{
     depends_on = [null_resource.anthos_deploy_cluster]
     provisioner "local-exec" {
        command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /root/anthos/ssh_key ubuntu@${var.admin_workstation_ip}:/home/ubuntu/cluster/ksa_token.txt /root/anthos"
     }
}
