#!/usr/bin/env bash
NEXUS_DOMAIN=nexus.linkaixin.com
NEXUS_PUSH_PORT=1443
docker_image_tgz_list=$(ls  *.image.tgz)
echo $docker_image_tgz_list

for image_tgz in $docker_image_tgz_list
do
      echo $image_tgz
      image_name=$(docker load --input $image_tgz | awk '{print $3}')
      echo "加载了docker镜像 image_name="$image_name
      result= $(echo $image_name | grep $NEXUS_DOMAIN)
      if [[ -z $result ]];
      then
           docker image tag $image_name ${NEXUS_DOMAIN}:${NEXUS_PUSH_PORT}/$image_name
           docker push ${NEXUS_DOMAIN}:${NEXUS_PUSH_PORT}/$image_name
      fi
       docker push ${NEXUS_DOMAIN}:${NEXUS_PUSH_PORT}/$image_name
done

