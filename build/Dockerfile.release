FROM busybox:ubuntu-14.04

MAINTAINER Nate Sweet <nathanjsweet@gmail.com>

RUN echo "nobody:x:1:1:nobody:/:/bin/sh" >> /etc/passwd

RUN echo "nobody:x:1:" >> /etc/group

USER nobody

EXPOSE 8080

CMD ["/bin/gohunservice", "-dictionaries=/go/src/gohunservice/dictionaries"]

COPY ./dictionaries /go/src/gohunservice/dictionaries
COPY ./lib/ /lib/

COPY gohunservice /bin/gohunservice

