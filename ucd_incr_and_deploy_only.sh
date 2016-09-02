#!/bin/bash

APPLICATION="UserMgmtApp"
ENVIRONMENT="UserDBAppDev"
USERNAME="admin"
PASSWORD="password"
UCD_SERVER_URL="https://13.78.48.145:8443"
LOG_FILE="`echo $1`.log"
CREATE_RESOURCE="/tmp/create_baseresource.json"
UPDATE_RESOURCE="/tmp/update_resourceagent.json"
MAP_COMPONENT="/tmp/map_component_withagent.json"
RUN_APP_PROCESS="/tmp/run_application_process.json"
RES_GRP="UserMgmtGrpA"
COMPONENT="ApplicationComponent"
UDCLIENT="/tmp/udclient/udclient"

rm -rf $CREATE_RESOURCE $UPDATE_RESOURCE $MAP_COMPONENT $RUN_APP_PROCESS

/bin/cat <<EOC >$CREATE_RESOURCE
{
  "name": "$RES_GRP",
  "description": "User Management Group A",
}
EOC

/bin/cat <<EOM >$UPDATE_RESOURCE
{
 "name"="`hostname -s`",
 "agent"="`hostname -s`",
 "parent"="/$RES_GRP"
}
EOM

/bin/cat <<EON >$MAP_COMPONENT
{
 "parent"="/$RES_GRP/`hostname -s`",
 "component"="$COMPONENT"
}
EON

/bin/cat <<EOR >$RUN_APP_PROCESS
{
  "application": "$APPLICATION",
  "description": "Deploying newest versions",
  "applicationProcess": "ApplicationDeployment",
  "environment": "$ENVIRONMENT",
  "onlyChanged": "true",
  "versions": [
    {
      "version": "latest",
      "component": "$COMPONENT"
    },
  ]
}
EOR

if [[ ! -f /tmp/udclient.zip ]]; then
cd /tmp
wget --no-check-certificate  $UCD_SERVER_URL/tools/udclient.zip
fi
unzip -o /tmp/udclient.zip

JRE_FOLDER=$(find /usr -type d -name jre|head -1)
J_HOME="JAVA_HOME=\"$JRE_FOLDER\""
sed -i "/^#JAVA_OPTS/a $J_HOME" $UDCLIENT

$UDCLIENT -weburl $UCD_SERVER_URL -username $USERNAME -password $PASSWORD  getComponentVersions -component ApplicationComponent  > /tmp/tmp.12345
value=`cat /tmp/tmp.12345|grep name|head -1|awk -F ":" '{print $NF}'|awk -F "." '{print $1}'|sed 's/"//g'`
value=`expr $value + 1`

$UDCLIENT -weburl $UCD_SERVER_URL -username $USERNAME -password $PASSWORD createVersion -component ApplicationComponent -name "$value.0"
$UDCLIENT -weburl $UCD_SERVER_URL -username $USERNAME -password $PASSWORD  requestApplicationProcess $RUN_APP_PROCESS >> $LOG_FILE
