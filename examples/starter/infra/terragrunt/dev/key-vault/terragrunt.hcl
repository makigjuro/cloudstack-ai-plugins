# dev / key-vault — configuration lives in _envcommon/key-vault.hcl; override inputs here.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/key-vault.hcl"
}
