hsi open_hw_design $env(XsaFile)
hsi set_repo_path $env(EmbeddedSW)
hsi generate_app -hw $env(XsaName) -os standalone -proc ps7_cortexa9_0 -app zynq_fsbl -compile -sw fsbl -dir $env(BuildDir)/fsbl
