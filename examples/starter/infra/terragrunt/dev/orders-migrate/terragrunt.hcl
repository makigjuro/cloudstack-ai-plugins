# dev / orders-migrate — configuration lives in _envcommon/orders-migrate.hcl; override inputs here.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/orders-migrate.hcl"
}
