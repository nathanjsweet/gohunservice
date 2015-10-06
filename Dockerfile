FROM golang

MAINTAINER Nate Sweet <nathanjsweet@gmail.com>

ENTRYPOINT /go/bin/gohunservice --dictionaries=/go/src/github.com/nathanjsweet/gohunservice/dictionaries

EXPOSE 8080

# Get gohun and build
RUN git clone --recursive https://github.com/nathanjsweet/gohun.git /go/src/gohun && cd /go/src/gohun && make && cd /
# Get gohunservice
RUN go get github.com/nathanjsweet/gohunservice
# Install gohunservice
RUN go install github.com/nathanjsweet/gohunservice