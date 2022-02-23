FROM debian:buster

WORKDIR /opt

ADD build_image_in_docker.sh .
ADD helpers/. helpers/.

RUN ./build_image_in_docker.sh
