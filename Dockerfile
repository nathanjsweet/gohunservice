FROM golang

MAINTAINER Nate Sweet <nathanjsweet@gmail.com>

CMD ["/go/bin/gohunservice --dictionaries=/go/src/gohunservice/dictionaries"]

EXPOSE 8080

# Get gohun and build
RUN git clone --recursive https://github.com/nathanjsweet/gohun.git /go/src/gohun && cd /go/src/gohun && make && cd /
# Set up gohunservice dir
RUN cd / && mkdir -p /go/src/gohunservice

# copy gohunservice
COPY ./dictionaries /go/src/gohunservice/
COPY ./main.go /go/src/gohunservice/

RUN go install gohunservice