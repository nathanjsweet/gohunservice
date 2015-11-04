#!/bin/bash

export GOPATH=$GOPATH
export GOBIN=$GOPATH/bin
gohun=$GOPATH/src/github.com/nathanjsweet/gohun
gohunservice=$GOPATH/src/github.com/nathanjsweet/gohunservice
echo "Preparing folders:"
rm -rf $gohun

echo "Fetching dependencies:"
git clone --recursive https://github.com/nathanjsweet/gohun.git $gohun
cd $gohun

echo "Building dependencies:"
make
cd $GOPATH

echo "Building gohunservice:"
go install github.com/nathanjsweet/gohunservice

echo "Preparing build folder for docker image:"
cd $GOPATH/src/github.com/nathanjsweet/gohunservice/build
cp $GOBIN/gohunservice $gohunservice/build/gohunservice
cp -r ../dictionaries ./dictionaries
mkdir -p ./lib
declare -A libMap
baseid=$(docker create busybox:ubuntu-14.04 /bin/sleep 10000)
docker start $baseid
lsR=$(docker exec $baseid ls /lib)
while read -r line; do
    libMap[$line]=1
done <<< "$lsR"
docker rm -vf $baseid
ldd $GOBIN/gohunservice | while read -r line; do
    name=$(echo "$line" | awk -F "=>" '{print $1}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    pt=$(echo "$line" | awk -F "=>" '{print $2}')
    path=$(echo "$pt" | awk -F " " '{print $1}')
    if [[ $path =~ \(.* || $path = "" || ${libMap[$name]} = 1 ]]
    then
	continue
    fi
    cp $path ./lib/
done

echo "Building docker image:"
docker build -t njs0/gohunservice:release .

echo "Cleaning up:"
rm -rf ./dictionaries
#rm -rf ./lib
rm gohunservice

