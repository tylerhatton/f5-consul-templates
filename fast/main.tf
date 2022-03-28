

provider "bigip" {
  address  = var.mgmt_url
  username = var.username
  password = var.password
}

data "terraform_remote_state" "bigip" {
  backend = "local"

  config = {
    path = "../bigip/terraform.tfstate"
  }
}

# generate zip file

data "template_file" "fast_template" {
  template = file("${path.module}/templates/fast.yaml.tpl")

  vars = {
    vip_address = data.terraform_remote_state.bigip.outputs.vip_internal_address
  }
}

data "archive_file" "template_zip" {
  type        = "zip"
  output_path = "${path.module}/Consul.zip"

  source {
    content  = data.template_file.fast_template.rendered
    filename = "fast.yaml"
  }
}

# deploy fast template

resource "bigip_fast_template" "consul" {
  name       = "Consul"
  source     = "${path.module}/Consul.zip"
  md5_hash   = data.archive_file.template_zip.output_md5
}

resource "bigip_fast_application" "nginx-webserver" {
  template   = "Consul/Consul"
  fast_json  = <<EOF
{
      "tenant": "Consul_Sync",
      "app": "Nginx",
      "virtualAddress": ${data.terraform_remote_state.bigip.outputs.vip_internal_address},
      "virtualPort": 8080
}
EOF
  depends_on = [bigip_fast_template.consul]
}
