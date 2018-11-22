#!/bin/bash
##
## Download a dump and import
##

source ${CONTAINER_SCRIPTS_PATH}/common.sh

## Vars
MYSQL_DEPLOY_DUMP=${MYSQL_DEPLOY_DUMP:-}
MYSQL_FORCE_DEPLOY_DUMP=${MYSQL_FORCE_DEPLOY_DUMP:-}
MYSQL_DUMP_SOURCE_URL=${MYSQL_DUMP_SOURCE_URL:-}
MYSQL_DUMP_SOURCE_USER=${MYSQL_DUMP_SOURCE_USER:-}
MYSQL_DUMP_SOURCE_PASSWORD=${MYSQL_DUMP_SOURCE_PASSWORD:-}


if [ -z "${MYSQL_DEPLOY_DUMP}" ]
then
  log_info 'No env var MYSQL_DEPLOY_DUMP set so we do not import a dump'
else
  if [ -z "${MYSQL_DUMP_SOURCE_URL}" ]
  then
    log_info 'MYSQL_DEPLOY_DUMP env var set but MYSQL_DUMP_SOURCE_URL not, we do do not know the dump source'
  else
     if [ -z "${MYSQL_DATABASE}" ]
     then
       log_info 'No MYSQL_DATABASE specified, we do not know where to import the dump'
     else
       MYSQL_TABLES=`mysql $mysql_flags $MYSQL_DATABASE -N -e 'show tables' 2>&1 | grep -v " Using a password" | wc -l`
       if [ "${MYSQL_TABLES}" == "0" ] || [ "${MYSQL_FORCE_DEPLOY_DUMP}" = true ]
       then
         log_info "${MYSQL_DATABASE}: ${MYSQL_TABLES} tables present"
         log_info "env var MYSQL_FORCE_DEPLOY_DUMP set to ${MYSQL_FORCE_DEPLOY_DUMP}"
         log_info "Going to download and import the dump: ${MYSQL_DUMP_SOURCE_URL}/${MYSQL_DEPLOY_DUMP}"
         # Download the dump
         RETRIES=6
         for ((i=0; i<$RETRIES; i++)); do
           echo "Downloading ${MYSQL_DUMP_SOURCE_URL}/${MYSQL_DEPLOY_DUMP}, attempt $((i+1))/$RETRIES"
           if [ -z "${MYSQL_DUMP_SOURCE_USER}" ]
           then
             curl -o /tmp/${MYSQL_DEPLOY_DUMP} ${MYSQL_DUMP_SOURCE_URL}/${MYSQL_DEPLOY_DUMP} && break
             sleep 10
           else
             log_info "HTTPAUTH credentials for MYSQL_DUMP_SOURCE_URL provided going to use them"
             curl -u "${MYSQL_DUMP_SOURCE_USER}:${MYSQL_DUMP_SOURCE_PASSWORD}" -o /tmp/${MYSQL_DEPLOY_DUMP} ${MYSQL_DUMP_SOURCE_URL}/${MYSQL_DEPLOY_DUMP} && break
             sleep 10
           fi
         done
         if [[ $i == $RETRIES ]]; then
           log_info "Download failed, giving up."
           unset MYSQL_DUMP_SOURCE_USER MYSQL_DUMP_SOURCE_PASSWORD
         else
           # Import the dump
           log_info "Download success, starting import now."
           mysql $mysql_flags $MYSQL_DATABASE < /tmp/${MYSQL_DEPLOY_DUMP} && log_info "Import finished successfully." || log_info "Error on import."
           rm -f /tmp/${MYSQL_DEPLOY_DUMP}
           unset MYSQL_DUMP_SOURCE_USER MYSQL_DUMP_SOURCE_PASSWORD
         fi
       else
         log_info "${MYSQL_DATABASE}: ${MYSQL_TABLES} tables present"
         log_info "env var MYSQL_FORCE_DEPLOY_DUMP set to ${MYSQL_FORCE_DEPLOY_DUMP}"
         log_info "Skipping the import."
      fi
    fi
  fi
fi
