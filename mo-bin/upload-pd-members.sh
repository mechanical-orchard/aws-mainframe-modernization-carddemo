#!/bin/bash

# Get the full path of this script
script_path="$(readlink -f "$0")"
script_dir="$(dirname "$script_path")"
carddemo_dir="$(dirname "$script_dir")"


# Upload directories in this repo as partitioned data sets
zowe zos-files ul dir-to-pds "$carddemo_dir/app/bms" 'AWS.M2.CARDDEMO.BMS' --host $HOST --port $PORT --user $IBMUSER --reject-unauthorized false --password $PASSWORD
zowe zos-files ul dir-to-pds "$carddemo_dir/app/cbl" 'AWS.M2.CARDDEMO.CBL' --host $HOST --port $PORT --user $IBMUSER --reject-unauthorized false --password $PASSWORD
zowe zos-files ul dir-to-pds "$carddemo_dir/app/cpy" 'AWS.M2.CARDDEMO.CPY' --host $HOST --port $PORT --user $IBMUSER --reject-unauthorized false --password $PASSWORD
zowe zos-files ul dir-to-pds "$carddemo_dir/app/jcl" 'AWS.M2.CARDDEMO.JCL' --host $HOST --port $PORT --user $IBMUSER --reject-unauthorized false --password $PASSWORD
zowe zos-files ul dir-to-pds "$carddemo_dir/app/proc" 'AWS.M2.CARDDEMO.PROC' --host $HOST --port $PORT --user $IBMUSER --reject-unauthorized false --password $PASSWORD

# zowe zos-files ul file-to-data-set "/Users/anna/src/aws-mainframe-modernization-carddemo/app/data/EBCDIC/AWS.M2.CARDDEMO.USRSEC.PS" "AWS.M2.CARDDEMO.USRSEC.PS" -b --host 52.118.207.136 --port 10443 --user $USERNAME --reject-unauthorized false --password $PASSWORD 
