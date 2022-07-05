hsi open_hw_design $env(XsaFile)
hsi set_repo_path $env(DeviceTreePath)
hsi create_sw_design device-tree -os device_tree -proc ps7_cortexa9_0
hsi generate_target -dir $env(BuildDir)/dts
