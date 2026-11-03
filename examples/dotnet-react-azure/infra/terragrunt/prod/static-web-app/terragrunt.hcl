# prod / static-web-app — configuration lives in _envcommon/static-web-app.hcl; override inputs here.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/static-web-app.hcl"
}
