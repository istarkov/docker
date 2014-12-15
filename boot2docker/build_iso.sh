#!/bin/bash
set -e

docker pull boot2docker/boot2docker

cat automount-shares.tpl | sed -E 's/{IP}/'`ifconfig vboxnet0 | tail -1 | awk '{print $2}'`'/1' > automount-shares
chmod 777 automount-shares

docker build --no-cache=true -t my-boot2docker-img .

docker run --rm my-boot2docker-img > boot2docker.iso

rm automount-shares
