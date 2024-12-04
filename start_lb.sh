#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
HAPROXY_CFG=$SCRIPT_DIR/haproxy.cfg
HAPROXY_IMAGE=haproxy:2.9-alpine

# Check if the script received exactly one argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <slurm_job_id>"
  exit 1
fi

# Store the argument in a variable
TRITON_SLURM_JOB_ID=$1

# Functions
generate_ips() {
    #get nodes from slurm
    nodes=$(scontrol show hostnames $(scontrol show job $TRITON_SLURM_JOB_ID --json | jq -r '.jobs[0].nodes'))
    nodes_array=( $nodes )
    num_nodes=${#nodes_array[@]}
    ips_address_array=()

    #convert to network friendly addresses
    for node_address in "${nodes_array[@]}"; do
        ips_address_array+=("${node_address}.chn.perlmutter.nersc.gov")
    done

}

load_balancer_cfg() {
    #generate the load balancer cfg in a tmp file
    LB_TMP_CFG=$(mktemp)
    chmod a+r $LB_TMP_CFG
    cat $HAPROXY_CFG > $LB_TMP_CFG
    echo "" >> $LB_TMP_CFG


    for ((n=0; n<num_nodes; n++)); do
        for i in 0 1 2 3; do
            echo -e "  server ${nodes_array[$n]}_${i} ${ips_address_array[$n]}:$((8001 + $i*10)) check proto h2" >> $LB_TMP_CFG
        done
    done
}

load_balancer() {
    echo "> Load balancer started..."
    shifter --module=none \
            --image=$HAPROXY_IMAGE \
            haproxy -f $LB_TMP_CFG
}

# Main 
main() {
    generate_ips
    load_balancer_cfg
    load_balancer
}

# Call the main function
main