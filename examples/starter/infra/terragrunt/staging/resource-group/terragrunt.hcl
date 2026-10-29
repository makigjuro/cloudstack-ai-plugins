# staging / resource-group — configuration lives in _envcommon/resource-group.hcl; override inputs here.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/resource-group.hcl"
}
