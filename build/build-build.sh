#!/bin/bash
mkdir -p ./tags
git rev-parse master > ./tags/gohunservicetag
docker build -t njs0/gohunservice:build -f Dockerfile.build .
