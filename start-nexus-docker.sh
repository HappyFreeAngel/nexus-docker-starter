#!/bin/bash
#确保shell 切换到当前shell 脚本文件夹
current_file_path=$(cd "$(dirname "$0")"; pwd)
cd ${current_file_path}

#输入参数如下
export NIC_NAME="ens160"
export NEXUS_IP_ADDRESS=""
export NEXUS_DOMAIN=nexus.cityworks.cn

export KEY_STORE_PASSWORD=your_password
export KEY_PASSWORD=your_password
export KEY_MANAGER_PASSWORD=your_password
export TRUST_STORE_PASSWORD=your_password

export NEXUS_VERSION=3.16.1
export NEXUS_IMAGE_NAME="sonatype/nexus3:3.16.1"
export KEYSTORE_ALIAS="jetty"
export HTTP_PORT=8081
export HTTPS_PORT=8443
export DOCKER_PRIVATE_HTTP_PORT=1080
export DOCKER_PRIVATE_HTTPS_PORT=1443
export DOCKER_GROUP_HTTP_PORT=2080
export DOCKER_GROUP_HTTPS_PORT=2443

# docker-private  http:1080 https:1443
# docker-proxy
#docker-group:  http: 2080  https: 2443

#以上参数可以通过修改manual-config-nexus.conf覆盖.
source manual-config-nexus.conf


echo "https://hub.docker.com/r/sonatype/nexus3/"
echo "默认用户admin 默认密码:admin123"

docker stop nexus
docker rm   nexus

if [[ -z "$NEXUS_IP_ADDRESS" ]];
then
    if [[ -z "$NIC_NAME" ]];
    then
          echo "没有指定NIC网卡无法获取正确的IP地址. 程序退出."
          exit 1
    fi
    export currentHostIp=`ip -4 address show $NIC_NAME | grep 'inet' |  grep -v grep | awk '{print $2}' | cut -d '/' -f1`
    export NEXUS_IP_ADDRESS=$currentHostIp
fi

echo "NEXUS_IP_ADDRESS=$NEXUS_IP_ADDRESS"

NEXUS_DATA_DIR="$current_file_path/nexus-data"
NEXUS_CONF_DIR="$current_file_path/nexus-conf"

`mkdir ${NEXUS_DATA_DIR}`
sudo chown -R 200 ${NEXUS_DATA_DIR}

if [[ ! -f "${NEXUS_DATA_DIR}/etc/nexus-default.properties" ]];
then
     `docker stop temp-nexus`
     `docker rm   temp-nexus`
     docker run --name temp-nexus -d ${NEXUS_IMAGE_NAME}
     sleep 5
     `rm -rf nexus-conf`
     `mkdir nexus-conf`
     docker cp temp-nexus:/opt/sonatype/nexus/etc nexus-conf/etc
     docker stop temp-nexus
     docker rm   temp-nexus
     echo "${NEXUS_IMAGE_NAME}缺省配置文件复制成功!"
     tree ${current_file_path}/nexus-conf

     #to do
     echo "替换/etc/jetty/jetty-https.xml里面的默认密码passowrd 为配置文件的密码"
     export KEY_STORE_PASSWORD=your_password
     export KEY_MANAGER_PASSWORD=your_password
     export TRUST_STORE_PASSWORD=your_password

     OLD_KEYSTORE_PASSWORD='KeyStorePassword\">password<'
     NEW_KEYSTORE_PASSWORD="KeyStorePassword\">${KEY_STORE_PASSWORD}<"

     OLD_KEY_MANAGER_PASSWORD='KeyManagerPassword\">password<'
     NEW_KEY_MANAGER_PASSWORD="KeyManagerPassword\">${KEY_MANAGER_PASSWORD}<"

     OLD_TRUST_STORE_PASSWORD='TrustStorePassword\">password<'
     NEW_TRUST_STORE_PASSWORD="TrustStorePassword\">${TRUST_STORE_PASSWORD}<"

     sed -i '' -e "s|$OLD_KEYSTORE_PASSWORD|$NEW_KEYSTORE_PASSWORD|g" $current_file_path/nexus-conf/etc/jetty/jetty-https.xml
     sed -i '' -e "s|$OLD_KEY_MANAGER_PASSWORD|$NEW_KEY_MANAGER_PASSWORD|g" $current_file_path/nexus-conf/etc/jetty/jetty-https.xml
     sed -i '' -e "s|$OLD_TRUST_STORE_PASSWORD|$NEW_TRUST_STORE_PASSWORD|g" $current_file_path/nexus-conf/etc/jetty/jetty-https.xml

    temp_jetty_path='${jetty.etc}'
    cat << EOF >$current_file_path/nexus-conf/etc/nexus-default.properties
# Jetty section
application-port=8081
application-host=0.0.0.0

application-port-ssl=8443

#下面代码有问题，to do ???? 无法写入文件.
nexus-args=${temp_jetty_path}/jetty.xml,${temp_jetty_path}/jetty-http.xml,${temp_jetty_path}/jetty-requestlog.xml,${temp_jetty_path}/jetty-https.xml,${temp_jetty_path}/jetty-http-redirect-to-https.xml

#nexus-args=${temp_jetty_path}/jetty.xml,${temp_jetty_path}/jetty-http.xml,${temp_jetty_path}/jetty-requestlog.xml

nexus-context-path=/${NEXUS_CONTEXT}

# Nexus section
nexus-edition=nexus-pro-edition
nexus-features=\
 nexus-pro-feature
nexus.clustered=false

EOF

#     echo "修改配置文件/etc/nexus-default.properties, 删除一行，增加2行."
#     sed -i '' -e '/nexus-args=*/d' $current_file_path/nexus-conf/etc/nexus-default.properties
#     echo "application-port-ssl=8443">> $current_file_path/nexus-conf/etc/nexus-default.properties
#     echo 'nexus-args=${jetty.etc}/jetty.xml,${jetty.etc}/jetty-http.xml,${jetty.etc}/jetty-requestlog.xml,${jetty.etc}/jetty-https.xml,${jetty.etc}/jetty-http-redirect-to-https.xml' >> $current_file_path/nexus-conf/etc/nexus-default.properties
fi
#生成https 相关证书
keytool -genkeypair -keystore keystore.jks -storepass ${KEY_STORE_PASSWORD}  -keypass ${KEY_PASSWORD} -alias ${KEYSTORE_ALIAS} -keyalg RSA -keysize 2048 -validity 5000 -dname "CN=*
.${NEXUS_DOMAIN}, OU=Example, O=Sonatype, L=Unspecified, ST=Unspecified, C=US" -ext "SAN=DNS:${NEXUS_DOMAIN},IP:${NEXUS_IP_ADDRESS}" -ext "BC=ca:true"

keytool -importkeystore -srckeystore keystore.jks -destkeystore keystore.jks -deststoretype pkcs12 -alias ${KEYSTORE_ALIAS}  -srcstorepass  ${KEY_STORE_PASSWORD}  -srckeypass ${KEY_PASSWORD}

#配置keystore
`mkdir -p ${NEXUS_CONF_DIR}/etc/ssl/`
cp keystore.jks ${NEXUS_CONF_DIR}/etc/ssl/


firewall-cmd --permanent --zone=public --add-port=${HTTP_PORT}/tcp
firewall-cmd --permanent --zone=public --add-port=${HTTPS_PORT}/tcp
firewall-cmd --permanent --zone=public --add-port=${DOCKER_PRIVATE_HTTP_PORT}/tcp
firewall-cmd --permanent --zone=public --add-port=${DOCKER_PRIVATE_HTTPS_PORT}/tcp
firewall-cmd --permanent --zone=public --add-port=${DOCKER_GROUP_HTTP_PORT}/tcp
firewall-cmd --permanent --zone=public --add-port=${DOCKER_GROUP_HTTPS_PORT}/tcp

firewall-cmd --reload


docker run -d \
--name nexus \
-p ${HTTP_PORT}:${HTTP_PORT} \
-p ${HTTPS_PORT}:${HTTPS_PORT} \
-p ${DOCKER_PRIVATE_HTTP_PORT}:${DOCKER_PRIVATE_HTTP_PORT} \
-p ${DOCKER_PRIVATE_HTTPS_PORT}:${DOCKER_PRIVATE_HTTPS_PORT} \
-p ${DOCKER_GROUP_HTTP_PORT}:${DOCKER_GROUP_HTTP_PORT} \
-p ${DOCKER_GROUP_HTTPS_PORT}:${DOCKER_GROUP_HTTPS_PORT} \
-v `pwd`/nexus-data:/nexus-data \
-v `pwd`/nexus-conf/etc:/opt/sonatype/nexus/etc \
-v /etc/localtime:/etc/localtime:ro \
-e INSTALL4J_ADD_VM_PARAMS="-Xms2g -Xmx2g -XX:MaxDirectMemorySize=3g  -Djava.util.prefs.userRoot=/some-other-dir" \
-e "TZ=Asia/Shanghai" \
${NEXUS_IMAGE_NAME}

echo "等待服务器启动..."
echo "准备导出自签名证书,给Nexus docker客户端服务器使用(如mesos-agent),请您耐心等待服务器启动,大概30秒左右"

max_wait_time_in_seconds=240 #最多等待240秒
while [ $max_wait_time_in_seconds -gt 0 ]
do
    result=$(docker logs nexus | grep 'Start RESTORE')
    if [[ -z $result ]];
    then
          sleep 5
          max_wait_time_in_seconds=$((max_wait_time_in_seconds-5))
    else
          echo "nexus启动成功"
          keytool -printcert -sslserver ${NEXUS_DOMAIN}:${HTTPS_PORT} -rfc > ${NEXUS_DOMAIN}.crt
          more ${NEXUS_DOMAIN}.crt

          ##下面这行代码有问题.
          ##keytool -export -alias ${KEYSTORE_ALIAS} -keystore keystore.jks -storepass ${STORE_PASS} -file ${NEXUS_DOMAIN}.crt  ##??

          cp $NEXUS_DOMAIN.crt   /etc/pki/ca-trust/source/anchors/${NEXUS_DOMAIN}.crt
          update-ca-trust

          echo " 请将证书文件${NEXUS_DOMAIN}.crt拷贝到所有需要推送拉取镜像的机器上,位置是:/etc/docker/certs.d/${NEXUS_DOMAIN}\:${DOCKER_PRIVATE_HTTPS_PORT}/${NEXUS_DOMAIN}.crt"
          echo " 请将证书文件${NEXUS_DOMAIN}.crt拷贝到所有需要推送拉取镜像的机器上,位置是:/etc/docker/certs.d/${NEXUS_DOMAIN}\:${DOCKER_GROUP_HTTPS_PORT}/${NEXUS_DOMAIN}.crt"
          echo " 然后就可以在远程机器上使用 1: docker login ${NEXUS_DOMAIN}:${DOCKER_GROUP_HTTPS_PORT} 拉取镜像了。"
          echo " 然后就可以在远程机器上使用 1: docker login ${NEXUS_DOMAIN}:${DOCKER_PRIVATE_HTTPS_PORT} 推送镜像了。"

          break
    fi
done
