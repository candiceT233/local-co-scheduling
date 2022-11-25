#!/bin/bash

# get env variables
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [ -f ${CWD}/env_var.sh ]; then
    source ${CWD}/env_var.sh
else
    echo "The environment configuration file (env_var.sh) doesn't exist. Exit....."
    exit
fi

TEST_NAME=$1
# LOG_DIR=$DEV2_DIR/scale_test
SIM_CMD="--residue 100 -n 2 -a 1000 -f 2000"


clean_env(){
    

    # only using 2 devices for now
    # remove previous results
    mkdir -p $DEV1_DIR/$HSLABS
    mkdir -p $DEV2_DIR/$HSLABS
    rm -rf $DEV2_DIR/molecular_dynamics_runs
    rm -rf $DEV2_DIR/aggregate.h5

    # rm -rf $SCRIPT_DIR/molecular_dynamics_runs 
    # rm -rf $SCRIPT_DIR/aggregate.h5

    mkdir $LOG_DIR
    # 0 to check IOs
    export GLOG_minloglevel=0

}

hermes_sim_agg_posix(){
    clean_env
    wait

    cd $SCRIPT_DIR
    killall hermes_daemon # clean up if daemon still alive
    # remove previous results

    # export GLOG_log_dir=$LOG_DIR
    # export FLAGS_logtostderr=0
    
    export HERMES_PAGE_SIZE=524288  # 1024 4096 8192 16384 32768 65536 131072 262144 524288 2097152 4194304 (4m) # default : 1048576

    # echo "HERMES_CONF=${HERMES_CONF}"
    # echo "HERMES_INSTALL_DIR=${HERMES_INSTALL_DIR}"

    echo "Running hermes_sim_agg_posix ..."
    start=$(date +%s)

    set -x 
    # Start a daemon
    HERMES_CONF=$HERMES_CONF $HERMES_INSTALL_DIR/bin/hermes_daemon &
    sleep 3

    # echo "Running sim_emulator.py with hermes posix ..."
    
    LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        HERMES_CONF=$HERMES_CONF \
        ADAPTER_MODE=SCRATCH \
        HERMES_STOP_DAEMON=0 \
        HERMES_CLIENT=1 \
        python3 $SCRIPT_DIR/sim_emulator.py $SIM_CMD \
        > >(tee $LOG_DIR/hm-sim.posix.log) 2>$LOG_DIR/hm-sim.posix.err

    ls $DEV2_DIR/molecular_dynamics_runs/*/* -hl # should not have file, buffered in hermes

    LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        HERMES_CONF=$HERMES_CONF \
        ADAPTER_MODE=SCRATCH \
        HERMES_STOP_DAEMON=1 \
        HERMES_CLIENT=1 \
        python3 $SCRIPT_DIR/aggregate.py -no_rmsd -no_fnc --input_path $DEV2_DIR --output_path $DEV2_DIR/aggregate.h5 \
        > >(tee $LOG_DIR/hm-agg.posix.log) 2>$LOG_DIR/hm-agg.posix.err
    
    set +x
    end=$(date +%s)
    ls -lrtah $DEV2_DIR | grep "aggregate.h5" # check file size for correctness
    tail -10 $LOG_DIR/hm-agg.posix.err

    echo -e "\n hermes_sim_agg_posix Elapsed Time: $(($end-$start)) seconds\n"
    
}

sim_agg_def(){
    clean_env
    wait

    cd $SCRIPT_DIR

    echo "Running sim_agg_def ..."
    start=$(date +%s)

    set -x 

    python3 $SCRIPT_DIR/sim_emulator.py $SIM_CMD \
    > >(tee $LOG_DIR/sim.log) 2>$LOG_DIR/sim.err

    ls $DEV2_DIR/molecular_dynamics_runs/*/* -hl # should not have file, buffered in hermes

    python3 aggregate.py -no_rmsd -no_fnc --input_path $DEV2_DIR --output_path $DEV2_DIR/aggregate.h5 \
      > >(tee $LOG_DIR/agg.log) 2>$LOG_DIR/agg.err
    
    set +x
    end=$(date +%s)
    ls -lrtah $DEV2_DIR | grep "aggregate.h5" # check file size for correctness

    echo -e "\n sim_agg_def Elapsed Time: $(($end-$start)) seconds\n"
    
}


if [ "$TEST_NAME" == "hm" ]
then 
  hermes_sim_agg_posix
  exit 0
fi

if [ "$TEST_NAME" == "def" ]
then 
  sim_agg_def
  exit 0
fi