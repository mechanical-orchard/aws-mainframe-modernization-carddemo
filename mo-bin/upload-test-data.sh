#!/bin/bash

# Get the full path of this script
script_path="$(readlink -f "$0")"
script_dir="$(dirname "$script_path")"
carddemo_dir="$(dirname "$script_dir")"

zowe zos-files ul file-to-data-set \
  "$carddemo_dir/app/data/EBCDIC/AWS.M2.CARDDEMO.ACCDATA.PS" "AWS.M2.CARDDEMO.ACCDATA.PS" -b \
  --host $HOST --port $PORT --user $IBMUSER \
  --reject-unauthorized false --password $PASSWORD

zowe zos-files ul file-to-data-set \
  "$carddemo_dir/app/data/EBCDIC/AWS.M2.CARDDEMO.ACCTDATA.PS" "AWS.M2.CARDDEMO.ACCTDATA.PS" -b \
  --host $HOST --port $PORT --user $IBMUSER \
  --reject-unauthorized false --password $PASSWORD

zowe zos-files ul file-to-data-set \
  "$carddemo_dir/app/data/EBCDIC/AWS.M2.CARDDEMO.CARDDATA.PS" "AWS.M2.CARDDEMO.CARDDATA.PS" -b \
  --host $HOST --port $PORT --user $IBMUSER \
  --reject-unauthorized false --password $PASSWORD

zowe zos-files ul file-to-data-set \
  "$carddemo_dir/app/data/EBCDIC/AWS.M2.CARDDEMO.CUSTDATA.PS" "AWS.M2.CARDDEMO.CUSTDATA.PS" -b \
  --host $HOST --port $PORT --user $IBMUSER \
  --reject-unauthorized false --password $PASSWORD

zowe zos-files ul file-to-data-set \
  "$carddemo_dir/app/data/EBCDIC/AWS.M2.CARDDEMO.TCATBALF.PS" "AWS.M2.CARDDEMO.TCATBALF.PS" -b \
  --host $HOST --port $PORT --user $IBMUSER \
  --reject-unauthorized false --password $PASSWORD

zowe zos-files ul file-to-data-set \
  "$carddemo_dir/app/data/EBCDIC/AWS.M2.CARDDEMO.TRANCATG.PS" "AWS.M2.CARDDEMO.TRANCATG.PS" -b \
  --host $HOST --port $PORT --user $IBMUSER \
  --reject-unauthorized false --password $PASSWORD

zowe zos-files ul file-to-data-set \
  "$carddemo_dir/app/data/EBCDIC/AWS.M2.CARDDEMO.TRANTYPE.PS" "AWS.M2.CARDDEMO.TRANTYPE.PS" -b \
  --host $HOST --port $PORT --user $IBMUSER \
  --reject-unauthorized false --password $PASSWORD

