hsi open_hw_design $evn(XsaFile)
hsi set_repo_path $env(EmbeddedSW)
hsi generate_app -hw $env(XsaName) -os standalone -proc ps7_cortexa9_0 -app zynq_fsbl -compile -sw fsbl -dir $env(FsblBuildDir)