#!/bin/bash
sh ./build-build.sh
id=$(docker create njs0/gohunservice:build)
docker cp $id:/go/bin/gohunservice - > gohunservice.tar
docker rm -v $id
tar -xvf gohunservice.tar gohunservice
rm gohunservice.tar
cp -r ../dictionaries ./dictionaries
docker build -t njs0/gohunservice:release -f Dockerfile.release .
rm -rf ./dictionaries
rm gohunservice
