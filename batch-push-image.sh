#!/usr/bin/env bash

images=$(docker images | grep 'nexus' | grep '1443' | awk '{print $1}')
for image in $images
do
   docker push $image
done