
#!/usr/bin/env bash

#确保shell 切换到当前shell 脚本文件夹
current_file_path=$(cd "$(dirname "$0")"; pwd)
cd ${current_file_path}
echo "usage $0  save_dir_path"

if [ $# != 1 ] ; then
  echo "使用当前目录保存docker镜像文件."
  read -p '使用当前目录保存docker镜像${current_file_path} [y/n]' userinput
  if [ $userinput == 'y' ];then
     save_image_dir_path=${current_file_path}
  else
     exit 1
  fi
else
   save_image_dir_path=$1
fi

echo "docker镜像的保存路径="$save_image_dir_path


image_list=$(docker images | awk 'NR>1' | awk '{print ""$1":"$2"" }')

for image_name in $image_list
    do
      image_file_name=$(echo $image_name | sed "s|:|-|g" | sed "s|/|-|g").image.tgz
      full_docker_image_file_path=$save_image_dir_path/$image_file_name
      echo "${image_name}--->${full_docker_image_file_path}"
      docker image save  $image_name | gzip > $full_docker_image_file_path
    done

