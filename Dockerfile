FROM ubuntu:latest

RUN apt update && \
    apt-get install iproute2 wireguard qrencode -y && \
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

EXPOSE 51820
COPY bootstrap.sh /

ENTRYPOINT bash -x bootstrap.sh

