#!/bin/bash

set -e

if [ -z "$WS_APIKEY" ]; then
  echo "You must set an API key!"
  exit 126
fi

PROJECT_NAME_STR=""
if [ -z "$WS_PROJECTNAME" ]; then
  IFS='/' read -a GH_REPO <<< "$GITHUB_REPOSITORY"
  PROJECT_NAME_STR="${GH_REPO[1]}"
else
  PROJECT_NAME_STR="$WS_PROJECTNAME"
fi

if [ -z "$WS_CONFIGFILE" ] && [ -z "$PROJECT_NAME_STR" ]; then
  echo "'projectName' or 'configFile' path must be set."
  exit 126
fi

PRODUCT_NAME_STR=""
if [ -n "$WS_PRODUCTNAME" ]; then
  PRODUCT_NAME_STR="-product $WS_PRODUCTNAME"
fi


# Download latest Unified Agent release from Whitesource
curl -LJO  https://github.com/whitesource/unified-agent-distribution/releases/latest/download/wss-unified-agent.jar

# verify jar signature
jarsigner -verify  wss-unified-agent.jar


#unset GOROOT passed automatically by setup-go
unset GOROOT

# don't exit if unified agent exits with error code
set +e
# Execute Unified Agent (2 settings)
if [ -z  "$WS_CONFIGFILE" ]; then
  java -jar wss-unified-agent.jar -noConfig true -apiKey $WS_APIKEY -project "$PROJECT_NAME_STR" $PRODUCT_NAME_STR\
    -d . -wss.url $WS_WSSURL -resolveAllDependencies true
else
  java -jar wss-unified-agent.jar -apiKey $WS_APIKEY -c "$WS_CONFIGFILE" -d .
fi

WS_EXIT_CODE=$?
echo "WS exit code: $WS_EXIT_CODE"

exit $WS_EXIT_CODE