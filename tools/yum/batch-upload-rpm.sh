#!/bin/env bash
#确保shell 切换到当前shell 脚本文件夹
current_file_path=$(cd "$(dirname "$0")"; pwd)
cd ${current_file_path}

rpm_file_list=$(ls *.rpm)
NEXUS_DOMAIN=nexus.linkaixin.com
YUM_HOSTED_PORT=8443
username=admin
password=admin123
#dir=7/os/x86_64/kubernetes/Packages/
#dir=7/os/x86_64/Packages/
#dir=kubernetes/1.15.0/centos1810/x86_64/
dir=x86_64/7/kubernetes/packages
#正确的客户端kubernetes.repo 用法  baseurl=https://nexus.linkaixin.com:8443/repository/yum-hosted/x86_64/7/kubernetes/
#不用添加packages
#-k 是表示不用验证证书,忽略证书验证(当使用自制证书时可以这样使用)

for file in $rpm_file_list
do
   echo "${file} uploading "
   curl -k -v -u admin:admin123 --upload-file ${file}  https://${NEXUS_DOMAIN}:${YUM_HOSTED_PORT}/repository/yum-hosted/${dir}/${file}
   #curl -k -v -u admin:admin123 --upload-file ${file}  https://nexus.linkaixin.com:8443/repository/yum-hosted/yum/x86_64/7/kubernetes/${file}
done