FROM  alpine:3.19
RUN apk add --no-cache bash iputils procps coreutils bind-tools
WORKDIR /app
COPY app/ /app/
RUN chmod +x /app/*.sh
ENTRYPOINT ["/app/diagnostic.sh"]
CMD ["help"]
