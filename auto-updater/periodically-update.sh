#!/bin/bash

set -ex

CHECK_INTERVAL_SEC=${CHECK_INTERVAL_SEC:-3600}

while true; do

  for image in ${IMAGES//,/ }
  do
      echo "Checking for updates on $image"

      CID=$(docker ps | grep "$image" | awk '{print $1}')
      docker pull $image

      for im in $CID
      do
          LATEST=`docker inspect --format "{{.Id}}" $image` # SHA of image
          RUNNING=`docker inspect --format "{{.Image}}" $im`
          NAME=`docker inspect --format '{{.Name}}' $im | sed "s/\///g"`
          echo "Latest:" $LATEST ", Running:" $RUNNING
          if [ "$RUNNING" != "$LATEST" ];then
              echo "Updating $NAME"
              docker stop $NAME
              docker start $NAME
          else
              echo "$NAME up to date"
          fi
      done
  done

  sleep $CHECK_INTERVAL_SEC
done

