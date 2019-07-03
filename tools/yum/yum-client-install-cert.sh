#!/bin/env bash
#确保shell 切换到当前shell 脚本文件夹
current_file_path=$(cd "$(dirname "$0")"; pwd)
cd ${current_file_path}

#输入参数如下
export NEXUS_DOMAIN=nexus.linkaixin.com
export NEXUS_VERSION=3.16.1
export NEXUS_IMAGE_NAME="sonatype/nexus3:3.16.1"
export HTTP_PORT=8081
export HTTPS_PORT=8443


keytool -printcert -sslserver ${NEXUS_DOMAIN}:${HTTPS_PORT} -rfc > ${NEXUS_DOMAIN}.crt
cert_status=$(cat ${NEXUS_DOMAIN}.crt | grep 'BEGIN CERTIFICATE')

if [[ -z $cert_status ]];
then
     echo "尝试输出证书,失败,程序退出..."
     exit
else
	cp ${NEXUS_DOMAIN}.crt /etc/pki/ca-trust/source/anchors/
    cd /etc/pki/ca-trust/source/anchors/
    update-ca-trust extract
fi

