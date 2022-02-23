FROM debian:buster

WORKDIR /opt

ADD build_image_in_docker.sh .
ADD helpers/. helpers/.

RUN IMAGE_BUILD_ONLY=true ./build_image_in_docker.sh
