terraform {
  required_providers {
    bigip = {
      source = "terraform-providers/bigip"
    }
  }
  required_version = ">= 0.13"
}

data "terraform_remote_state" "f5" {
  backend = "remote"
  config = {
    organization = "pcarey-org"
    workspaces = {
      name = "f5-bigip-tf-deploy"
    }
  }
}

provider "bigip" {
  //address  = [data.terraform_remote_state.f5.outputs.bigip_mgmt_dns[0]]
  address = "${join(" ", data.terraform_remote_state.f5.outputs.bigip_mgmt_dns)}"
  username = var.username
  password = data.terraform_remote_state.f5.outputs.password.result
  port = var.port
}

resource "bigip_ltm_monitor" "monitor" {
  name   = "/Common/terraform_monitor"
  parent = "/Common/http"
}
resource "bigip_ltm_pool" "pool" {
  name                   = "/Common/Axiom_Environment_APP1_Pool"
  load_balancing_mode    = "round-robin"
  minimum_active_members = 1
  monitors               = [bigip_ltm_monitor.monitor.name]
}

resource "bigip_as3" "as3-example1" {
  as3_json = file("example1.json")
}
