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
git reset 4a684448 --hard

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
ldd $GOBIN/gohunservice | while read -r line; do
    name=$(echo "$line" | awk -F "=>" '{print $1}')
    pt=$(echo "$line" | awk -F "=>" '{print $2}')
    path=$(echo "$pt" | awk -F " " '{print $1}')
    if [[ $path =~ \(.* || $path = "" || \
	$name =~ libm\.so\.6 || \
        $name =~ ld\-linux\-x86\-64\.so\.2 || \
	$name =~ libdl\.so\.2 || \
	$name =~ libnsl\.so\.1 || \
	$name =~ libnss_dns\.so\.2 || \
	$name =~ libnss_hesiod\.so\.2 || \
	$name =~ libnss_nisplus\.so\.2 || \
	$name =~ libresolv\.so\.2 || \
	$name =~ libc\.so\.6   || \
	$name =~ libnss_compat\.so\.2 || \
	$name =~ libnss_files\.so\.2 || \
	$name =~ libnss_nis\.so\.2 || \
	$name =~ libpthread\.so\.0 || \
	$name =~ librt\.so\.1 ]]
    then
	continue
    fi
    cp $path ./lib/
done

echo "Building docker image:"
docker build -t njs0/gohunservice:release -f Dockerfile.release .

echo "Cleaning up:"
rm -rf ./dictionaries
rm -rf ./lib
rm gohunservice

