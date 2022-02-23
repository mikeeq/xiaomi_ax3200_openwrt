FROM debian:buster

WORKDIR /opt

ADD build_image_in_docker.sh .
ADD helpers/. helpers/.

ENV IMAGE_BUILD_ONLY=true

RUN ./build_image_in_docker.sh
