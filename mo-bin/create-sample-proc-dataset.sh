#!/bin/bash

script_path="$(readlink -f "$0")"
script_dir="$(dirname "$script_path")"


allocate_job_id=$(zowe zos-jobs submit local-file $script_dir/ALLOCATE_PROC_DATASETS.jcl --rfj --host $HOST --port $PORT --user $IBMUSER --reject-unauthorized false --password $PASSWORD | jq -r .data.jobid)

echo "Submitted job $allocate_job_id"

alcstatus="UNKNOWN"
# When the status is OUTPUT it indicates that the job itself is no longer running
# but its output is available to be examined or managed.
while [[ "$alcstatus" != "OUTPUT" ]]; do
    echo "Checking status of job $allocate_job_id"
    alcstatus=$(zowe zos-jobs view job-status-by-jobid "$allocate_job_id" --rff status --rft string --host $HOST --port $PORT --user $IBMUSER --reject-unauthorized false --password $PASSWORD)
    echo "Current status is $alcstatus"
    sleep 5
done;

echo "DONE"
