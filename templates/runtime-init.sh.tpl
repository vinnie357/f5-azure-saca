#!/bin/bash
# https://github.com/f5devcentral/f5-bigip-runtime-init
# azure
#
# logging
LOG_FILE=${onboard_log}
if [ ! -e $LOG_FILE ]
then
     touch $LOG_FILE
     exec &>>$LOG_FILE
else
    #if file exists, exit as only want to run once
    exit 0
fi
exec 1>$LOG_FILE 2>&1
# wait bigip
source /usr/lib/bigstart/bigip-ready-functions
wait_bigip_ready
route add -net default gw ${mgmtGateway} netmask 0.0.0.0 dev mgmt metric 0 || :
#
# sca
#
# as3
cat > /config/as3.json <<EOF
${AS3_Document}
EOF
externalVip=$(curl -sf --retry 20 -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface?api-version=2017-08-01" | jq -r '.[1].ipv4.ipAddress[1].privateIpAddress')
# get as3 values
sed -i "s/-external-virtual-address-/$externalVip/g" /config/as3.json
# tmos init
# configure
mkdir -p /config/cloud
# https://github.com/f5devcentral/f5-bigip-runtime-init/blob/develop/src/schema/base_schema.json
cat  <<EOF > /config/cloud/cloud_config.yaml
---
runtime_parameters:
  - name: HOST_NAME
    type: metadata
    metadataProvider:
        environment: azure
        type: compute
        field: name
pre_onboard_enabled:
  - name: mgmt route metric
    type: inline
    commands:
      - /bin/tmsh bash -c "route add -net default gw ${mgmtGateway} netmask 0.0.0.0 dev mgmt metric 0 || :"
  - name: provision_rest
    type: inline
    commands:
      - /usr/bin/setdb provision.extramb 500
      - /usr/bin/setdb restjavad.useextramb true
      - /usr/bin/setdb setup.run false
  - name: expand_rest_storage
    type: inline
    commands:
      - /bin/tmsh modify /sys disk directory /appdata new-size 52256768
      - /bin/tmsh save sys config
  - name: metadata_routes
    type: inline
    commands:
      - /bin/tmsh modify sys db config.allow.rfc3927 value enable
      - /bin/tmsh modify sys global-settings mgmt-dhcp disabled
      - /bin/tmsh bash -c "tmsh create sys management-route metadata-route network 169.254.169.254/32 gateway ${mgmtGateway} || :"
      - /bin/tmsh save sys config
extension_packages:
  install_operations:
    - extensionType: do
      extensionVersion: ${doVersion}
    - extensionType: as3
      extensionVersion: ${as3Version}
    - extensionType: ts
      extensionVersion: ${tsVersion}
    - extensionType: cf
      extensionVersion: ${cfVersion}
    - extensionType: ilx
      extensionUrl: https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v${fastVersion}/f5-appsvcs-templates-${fastVersion}-1.noarch.rpm
      extensionVersion: ${fastVersion}
      extensionVerificationEndpoint: /mgmt/shared/fast/info
extension_services:
  service_operations:
    - extensionType: do
      type: inline
      value: ${DO_Document}
    - extensionType: as3
      type: url
      value: file:///config/as3.json
post_onboard_enabled:
  - name: do stuff here
    type: inline
    commands:
      - /bin/tmsh list auth parition
EOF
cat  <<EOF > /config/cloud/as3_config.yaml
---
runtime_parameters:
  - name: HOST_NAME
    type: metadata
    metadataProvider:
        environment: azure
        type: compute
        field: name
extension_services:
  service_operations:
    - extensionType: as3
      type: url
      value: file:///config/as3.json
EOF
# # Download
# initVersion="${initVersion}"
# PACKAGE_URL="https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v$${initVersion}/dist/f5-bigip-runtime-init-$${initVersion}-1.gz.run"
# for i in {1..30}; do
#     curl -fv --retry 1 --connect-timeout 5 -L "$${PACKAGE_URL}" -o "/var/config/rest/downloads/$${PACKAGE_URL##*/}" && break || sleep 10
# done
# # Install
# bash /var/config/rest/downloads/f5-bigip-runtime-init-$${initVersion}-1.gz.run -- '--cloud azure'
# install run-time-init

initVersion="${initVersion}"
curl -o /tmp/f5-bigip-runtime-init-$${initVersion}-1.gz.run https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v$${initVersion}/dist/f5-bigip-runtime-init-$${initVersion}-1.gz.run && bash /tmp/f5-bigip-runtime-init-$${initVersion}-1.gz.run -- '--cloud azure'
# debug
# error,warn,info,debug,silly
export F5_BIGIP_RUNTIME_INIT_LOG_LEVEL=debug
# run
wait_bigip_ready
echo "---- running run-time-init ----"
route add -net default gw ${mgmtGateway} netmask 0.0.0.0 dev mgmt metric 0 || :
route
f5-bigip-runtime-init --config-file /config/cloud/cloud_config.yaml
wait_bigip_ready
route add -net default gw ${mgmtGateway} netmask 0.0.0.0 dev mgmt metric 0 || :
sleep 30
echo "====as3 2===="
f5-bigip-runtime-init --config-file /config/cloud/as3_config.yaml
sleep 30
echo "====as3 3===="
f5-bigip-runtime-init --config-file /config/cloud/as3_config.yaml
sleep 30
echo "====as3 4===="
f5-bigip-runtime-init --config-file /config/cloud/as3_config.yaml
tail /var/log/restnoded/restnoded.log
tmsh list auth partition
echo "==== Done ===="
exit 0
