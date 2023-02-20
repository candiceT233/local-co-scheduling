#!/bin/bash  
#SBATCH -A oddite
#SBATCH --job-name="hm_co"
#SBATCH -N 2
#SBATCH -n 6
#SBATCH --time=01:30:00
#SBATCH --output=R_%x.out                                        
#SBATCH --error=R_%x.err

module purge
module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh

ulimit -c unlimited
. $HOME/spack/share/spack/setup-env.sh

source /qfs/people/tang584/scripts/local-co-scheduling/env_var.sh

# source /qfs/people/tang584/scripts/local-co-scheduling/load_hermes_deps.sh

set -x

NODE_COUNT=$SLURM_JOB_NUM_NODES
MD_RUNS=6
ITER_COUNT=1 # TBD
# GPU_PER_NODE=6
MD_START=0
MD_SLICE=$(($MD_RUNS/$NODE_COUNT))
NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`

# echo "SLURM_STEP_NUM_TASKS = $SLURM_STEP_NUM_TASKS"
# echo "NODE_NAMES = $NODE_NAMES"
echo "SLURM_JOB_NODELIST = $SLURM_JOB_NODELIST"
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

SIMULATION (){
    task_id=$(seq -f "task%04g" $1 $1)
    node_id=$2

    SIM_CMD="--residue 100 -n 1 -a 100 -f 100 --output_task $task_id"

    source $PY_VENV/bin/activate
    srun -w $node_id -n1 -N1 --exclusive \
        mpirun -np 1 \
        -x LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        -x HERMES_CONF=$HERMES_CONF \
        -x ADAPTER_MODE=SCRATCH \
        -x HERMES_STOP_DAEMON=0 \
        -x HERMES_CLIENT=1 \
        python3 $SCRIPT_DIR/sim_emulator.py $SIM_CMD &


}

AGGREGATE (){
    # task_id=task0000
    AGG_CMD="-no_rmsd -no_fnc --input_path $DEV2_DIR --output_path $DEV2_DIR/aggregate.h5"

    source $PY_VENV/bin/activate
    srun -N1 mpirun -np 1 \
        -x LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        -x HERMES_CONF=$HERMES_CONF \
        -x ADAPTER_MODE=SCRATCH \
        -x HERMES_STOP_DAEMON=1 \
        -x HERMES_CLIENT=1 \
        python3 $SCRIPT_DIR/aggregate.py $AGG_CMD

}

# mpirun -np 2 --map-by ppr:1:node --host $hostlist

hostname;date;
# Start a daemon
mpirun -np $NODE_COUNT --map-by ppr:1:node --host $hostlist killall hermes_daemon

mpirun -np $NODE_COUNT --map-by ppr:1:node --host $hostlist -x HERMES_CONF=${HERMES_CONF} ${HERMES_INSTALL_DIR}/bin/hermes_daemon &

# mpirun -np $NODE_COUNT --map-by ppr:1:node --host $hostlist sleep 3
sleep 3

for iter in $(seq $ITER_COUNT)
do

    # STAGE 1: SIMULATION
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

    wait

    echo "Simulation finished..."
    ls $DEV2_DIR/molecular_dynamics_runs/*/* -hl # check file size for correctness

    # STAGE 2: Aggregate
    # srun -N1 $( AGGREGATE )
    AGGREGATE
    wait

    echo "Aggregation finished..."
    ls -lrtah $DEV2_DIR | grep "aggregate.h5" # check file size for correctness

done

hostname;date;

sacct -j $SLURM_JOB_ID -o jobid,submit,start,end,state

rm -rf $SCRIPT_DI/core.*