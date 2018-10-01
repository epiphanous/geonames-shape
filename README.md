# Geonames Shape

Download and reshape geonames.

## Backfill

Run `./backfill.sh` to download and reshape geonames into a set of tab delimited text files in the export directory.

## Docker Disk Space

Depending on your docker configuration, you might get errors related to disk filling up. To resolve these, you either need to create free space in your docker disk image by removing exited containers and unused images or increase the size of your docker disk image via the docker app's preferences.

To remove stopped containers and unused images, try:

```bash
$ docker rm $(docker ps -a -q)
$ docker rmi $(docker images | grep '<none>')
```

