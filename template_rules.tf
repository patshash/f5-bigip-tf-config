/*variable "tenant" {
  type = string
}
variable "vip_address" {
  type = string
}

variable "rule_name" {
  type = string
}

variable "rule_description" {
  type = string
}
*/
locals {
  # Take a directory of JSON files, read each one and bring them in to Terraform's native data set
  f5_rules = [ for file in fileset(path.module, "f5_rules/*.json") : jsondecode(file(file)) ]
  # Take that data set and format it so that it can be used with the for_each command by converting it to a map
  # where each top level key is a unique identifier.
  # In this case I am using the common_name key from my example JSON files
  f5_rules_map = {for rule_block in toset(local.f5_rules): rule_block.rule_name => rule_block}
}


data "template_file" "init" {
  template = "${file("ex_template.tpl")}"
  for_each = local.f5_rules_map
  vars = {
    RULE_NAME = each.value.rule_name
    RULE_DESCRIPTION = each.value.rule_description
    TENANT = each.value.tenant
    VIP_ADDRESS = each.value.vip_address
    POOL_MEMBER1 = each.value.pool_member1
    POOL_MEMBER2 = each.value.pool_member2
    SERVICE_PORT = each.value.service_port
  }
}
resource "bigip_as3"  "as3-example" {
  for_each = local.f5_rules_map
     as3_json = data.template_file.init[each.key].rendered
     #tenant_filter = var.tenant
}
