FROM ubuntu:16.04

RUN apt-get update -y && apt-get install -yq netcat-openbsd

COPY netcat.sh /netcat.sh
RUN chmod +x /netcat.sh

RUN touch /var/log/netcat.log

ENTRYPOINT ["/netcat.sh"]