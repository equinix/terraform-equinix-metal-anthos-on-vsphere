provider "packet" {
    auth_token = "${var.auth_token}"
}

resource "packet_project" "new_project" {
    name = "${var.project_name}"
    organization_id = "${var.organization_id}"
}