#!/bin/bash

export GOPATH=$GOPATH
export GOBIN=$GOPATH/bin
gohun=$GOPATH/src/github.com/nathanjsweet/gohun
gohunservice=$GOPATH/src/github.com/nathanjsweet/gohunservice
echo "Fetching dependencies:"
if [ ! -d "$gohun" ]
then
    git clone --recursive https://github.com/nathanjsweet/gohun.git $gohun
fi
cd $gohun
git pull origin master
git reset 6f585f74262aa113a2635528bc28cca8c2a0a03e --hard

echo "Building dependencies:"
make
cd $GOPATH

echo "Building gohunservice:"
go install github.com/nathanjsweet/gohunservice

echo "Preparing build folder for docker image:"
cd $GOPATH/src/github.com/nathanjsweet/gohunservice/build
cp $GOBIN/gohunservice $gohunservice/build/gohunservice
cp -r ../dictionaries ./dictionaries

# This is the cool generic stuff about making busy-box
# correcly grab the necessary lib files.
mkdir -p ./lib
# Make map of what libs actually exist in the busy box image.
declare -A libMap
baseid=$(docker create busybox:ubuntu-14.04 /bin/sleep 10000)
docker start $baseid
lsR=$(docker exec $baseid ls /lib)
while read -r line; do
    libMap[$line]=1
done <<< "$lsR"
docker rm -vf $baseid
# Get a list of the libs that the go binary references, and
# add the ones that aren't in the busy box libMap
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
rm -rf ./lib
rm gohunservice

