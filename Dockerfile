FROM owasp/glue:raw-latest

WORKDIR /glue

RUN apk add --update --no-cache jq

ENV GLUE_FILE=""

COPY --chown=root:1001 . .

RUN chmod +x run_glue.sh