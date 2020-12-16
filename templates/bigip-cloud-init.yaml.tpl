#cloud-config

# boot commands
# default: none
# this is very similar to runcmd, but commands run very early
# in the boot process, only slightly after a 'boothook' would run.
# bootcmd should really only be used for things that could not be
# done later in the boot process.  bootcmd is very much like
# boothook, but possibly with more friendly.
# - bootcmd will run on every boot
# - the INSTANCE_ID variable will be set to the current instance id.
# - you can use 'cloud-init-per' command to help only run once
bootcmd:
    - [ cloud-init-per, once, mycmd3, sh, -xc, "/usr/bin/setdb provision.extramb 500"  ]
    - [ cloud-init-per, once, mycmd4, sh, -xc, "/usr/bin/setdb restjavad.useextramb true" ]
    - [ cloud-init-per, once, mycmd5, sh, -xc, "/usr/bin/setdb setup.run false" ]
