# prod / container-app-environment — configuration lives in _envcommon/container-app-environment.hcl; override inputs here.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/container-app-environment.hcl"
}
