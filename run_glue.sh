#!/bin/sh

# Abort script on error
set -e

GLUE_FILE=$1
REPORT_FILE=$2


jq -f jq_pattern $REPORT_FILE > /tmp/output.json

ruby /glue/bin/glue -t Dynamic \
  -T /tmp/output.json \
  -f json \
  --finding-file-path $GLUE_FILE \
  --mapping-file zaproxy_mapping.json \
  -z