#!/bin/env bash
`mkdir -p /etc/yum.repos.d/backup`
mv /etc/yum.repos.d/*.repo  /etc/yum.repos.d/backup
cp *.repo /etc/yum.repos.d/
yum clean all; yum makecache;
yum repolist;
