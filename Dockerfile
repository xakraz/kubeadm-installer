FROM alpine
RUN apk --update add bash curl ca-certificates
COPY files/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
