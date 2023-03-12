#!/bin/bash  
#SBATCH -A oddite
#SBATCH --job-name="hm_co"
#SBATCH  --exclude=node[01-25]
#SBATCH -N 4
#SBATCH -n 4
#SBATCH --time=00:30:00
#SBATCH --output=R_%x.out                                        
#SBATCH --error=R_%x.err


module purge
module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 #openmpi/4.1.3
source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh

# ulimit -c unlimited
. $HOME/spack/share/spack/setup-env.sh
source /qfs/people/tang584/scripts/local-co-scheduling/load_hermes_deps.sh

# load environment variables for Hermes
source /qfs/people/tang584/scripts/local-co-scheduling/env_var.sh 
# source /qfs/people/tang584/scripts/local-co-scheduling/load_hermes_deps.sh


NODE_COUNT=$SLURM_JOB_NUM_NODES
MD_RUNS=4
ITER_COUNT=1 # TBD
# GPU_PER_NODE=6
MD_START=0
MD_SLICE=$(($MD_RUNS/$NODE_COUNT))

# echo "SLURM_STEP_NUM_TASKS = $SLURM_STEP_NUM_TASKS"
# get nodelist to hermes config file
if [ "$NODE_COUNT" = "1" ]; then
    sed "s/\$HOST_BASE_NAME/\"localhost\"/" $HERMES_DEFAULT_CONF  > $HERMES_CONF
    sed -i "s/\$HOST_NUMBER_RANGE/ /" $HERMES_CONF
else
    sed "s/\$HOST_BASE_NAME/\"node\"/" $HERMES_DEFAULT_CONF  > $HERMES_CONF
    rpc_host_number_range=$(echo "$SLURM_JOB_NODELIST" | grep -Po '[\[].*[\]]')
    sed -i "s/\$HOST_NUMBER_RANGE/${rpc_host_number_range}/" $HERMES_CONF
fi

NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`
hostlist=$(echo -e "$NODE_NAMES" | xargs | sed -e 's/ /,/g')
echo "hostlist = $hostlist"

# setup  dir
mkdir -p $DEV1_DIR/hermes_slabs
mkdir -p $DEV2_DIR/hermes_swaps

# mkdir -p $DEV3_DIR
rm -rf $DEV1_DIR/hermes_slabs/*
rm -rf $DEV2_DIR/hermes_swaps/*
rm -rf $DEV2_DIR/aggregate.h5
rm -rf $DEV2_DIR/molecular_dynamics_runs

# set -x

SIMULATION (){
    task_id=$(seq -f "%04g" $1 $1)
    node_id=$2

    SIM_CMD="--residue 100 -n 1 -a 100 -f 100 --output_task $task_id"
        # -genv HERMES_CLIENT_CONF=${HERMES_CLIENT_CONF} \
    
    # export LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so
    # export HERMES_CONF=$HERMES_CONF
    # export ADAPTER_MODE=SCRATCH
    # export HERMES_STOP_DAEMON=0
    # export HERMES_CLIENT=1

    source $PY_VENV/bin/activate
    srun -w $node_id -n1 -N1 --exclusive \
        mpirun -np 1 \
        -genv LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        -genv HERMES_CONF=$HERMES_CONF \
        -genv ADAPTER_MODE=SCRATCH \
        -genv HERMES_STOP_DAEMON=0 \
        -genv HERMES_CLIENT=1 \
        python $SCRIPT_DIR//src/sim_emulator.py $SIM_CMD &

}

AGGREGATE (){
    # task_id=task0000
    AGG_CMD="-no_rmsd -no_fnc --input_path $DEV2_DIR --output_path $DEV2_DIR/aggregate.h5"
            # -genv HERMES_CLIENT_CONF=${HERMES_CLIENT_CONF} \

    source $PY_VENV/bin/activate

    # export LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so
    # export HERMES_CONF=$HERMES_CONF
    # export ADAPTER_MODE=SCRATCH
    # export HERMES_STOP_DAEMON=1
    # export HERMES_CLIENT=1

    mpirun -np 1 \
        -genv LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        -genv HERMES_CONF=$HERMES_CONF \
        -genv ADAPTER_MODE=SCRATCH \
        -genv HERMES_STOP_DAEMON=1 \
        -genv HERMES_CLIENT=1 \
        python $SCRIPT_DIR//src/aggregate.py $AGG_CMD
    
}

START_HERMES_DAEMON (){
    for node in $NODE_NAMES
    do
        echo $node
        # export HERMES_CONF=${HERMES_CONF}
        srun -w $node -n1 -N1 mpirun -np 1 -genv HERMES_CONF=${HERMES_CONF} ${HERMES_INSTALL_DIR}/bin/hermes_daemon &
        # mpirun -np $NODE_COUNT --map-by ppr:1:node --host $hostlist -x HERMES_CONF=${HERMES_CONF} ${HERMES_INSTALL_DIR}/bin/hermes_daemon &
    done
    sleep 3
}

STOP_HERMES_DAEMON(){
    for node in $NODE_NAMES
    do
        srun -w $node -n1 -N1 killall hermes_daemon
    done
}

# mpirun -np 2 --map-by ppr:1:node --host $hostlist

hostname;date;
# Start a daemon
# START_HERMES_DAEMON
# mpirun -np $NODE_COUNT --map-by ppr:1:node --host $hostlist killall hermes_daemon
# mpirun -np $NODE_COUNT --map-by ppr:1:node --host $hostlist -x HERMES_CONF=${HERMES_CONF} ${HERMES_INSTALL_DIR}/bin/hermes_daemon &


mpirun -np $NODE_COUNT -ppn 1 -host $hostlist killall hermes_daemon
# set -x
mpirun -verbose -np $NODE_COUNT -ppn 1 -host $hostlist -genv HERMES_CONF $HERMES_CONF $HERMES_INSTALL_DIR/bin/hermes_daemon &
sleep 3
# START_HERMES_DAEMON
# set +x

# export GLOG_minloglevel=0
# export FLAGS_logtostderr=0

for iter in $(seq $ITER_COUNT)
do
    start_time=$SECONDS
    (# STAGE 1: SIMULATION
    for node in $NODE_NAMES
    do
        while [ $MD_SLICE -gt 0 ] && [ $MD_START -lt $MD_RUNS ]
        do
            echo $node
            SIMULATION $MD_START $node
            MD_START=$(($MD_START + 1))
            MD_SLICE=$(($MD_SLICE - 1))
        done
        MD_SLICE=$(($MD_RUNS/$NODE_COUNT))
    done

    wait)

    

    duration=$(($SECONDS - $start_time))
    echo "Simulation finished... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
    # stage out
    # $HERMES_INSTALL_DIR/stage-out $DEV2_DIR/molecular_dynamics_runs
    ls $DEV2_DIR/molecular_dynamics_runs/*/* -hl # check file size for correctness

    # STAGE 2: Aggregate
    start_time=$SECONDS
    srun -N1 $( AGGREGATE )
    duration=$(($SECONDS - $start_time))
    echo "Aggregation finished... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

    # stage out
    # srun -N1 mpirun -np 1 $HERMES_INSTALL_DIR/stage-out $DEV2_DIR/aggregate.h5

    ls -lrtah $DEV2_DIR | grep "aggregate.h5" # check file size for correctness
    

done

hostname;date;

sacct -j $SLURM_JOB_ID -o jobid,submit,start,end,state

rm -rf $SCRIPT_DI/core.*