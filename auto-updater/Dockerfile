FROM alpine:3.14.2

RUN apk update && apk add bash docker git openssh
SHELL ["/bin/bash", "-c"]

COPY ./periodically-update.sh /updater/
WORKDIR /updater

CMD ["./periodically-update.sh"]
