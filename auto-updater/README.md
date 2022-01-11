Inspired by

https://stackoverflow.com/a/26548914
https://github.com/stephanlindauer/docker-compose-updater

This will update docker images within a docker-compose run. It works by running a simple script that pulls a given
image and sees if that's different from what's running. If so, it uses the docker socket (provided as a volume) to stop
and start the container. This will cause brief outages.