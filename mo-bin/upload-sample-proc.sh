#!/bin/bash

# Get the full path of this script
script_path="$(readlink -f "$0")"
script_dir="$(dirname "$script_path")"
carddemo_dir="$(dirname "$script_dir")"

zowe zos-files ul dir-to-pds "$carddemo_dir/samples/proc" 'AWS.M2.CARDDEMO.PRC.UTIL' --host $HOST --port $PORT --user $IBMUSER --reject-unauthorized false --password $PASSWORD
