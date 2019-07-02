#!/usr/bin/env bash

docker stop nexus
docker rm   nexus

rm -rf nexus-conf
rm -rf nexus-data
rm -rf keystore.jk*
