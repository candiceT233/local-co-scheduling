SKIP_OPENMM=false
SHORTENED_PIPELINE=true
S1_HM=true
MD_RUNS=1 #12
ITER_COUNT=1 # TBD
SIM_LENGTH=0.01
SIZE=$(echo "$SIM_LENGTH * 1000" | bc)
SIZE=${SIZE%.*}
TRIAL=0
ADAPTER_MODE="WORKFLOW"

TEST_OUT_PATH=hermes_test_${SIZE}ps_i${ITER_COUNT}_${TRIAL}

EXPERIMENT_PATH=$HOME/scripts/ddmd_runs/$TEST_OUT_PATH
DDMD_PATH=$HOME/scripts/deepdrivemd
MOLECULES_PATH=$HOME/scripts/molecules
mkdir -p $EXPERIMENT_PATH

GPU_PER_NODE=6
MD_START=0
NODE_COUNT=1
MD_SLICE=$(($MD_RUNS/$NODE_COUNT))
STAGE_IDX=0
STAGE_IDX_FORMAT=$(seq -f "stage%04g" $STAGE_IDX $STAGE_IDX)

# NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`
NODE_NAMES="localhost"


if [ "$SKIP_OPENMM" == true ]
then
    # keep molecular_dynamics_runs
    rm -rf $EXPERIMENT_PATH/agent_runs $EXPERIMENT_PATH/inference_runs $EXPERIMENT_PATH/machine_learning_runs $EXPERIMENT_PATH/model_selection_runs
    ls $EXPERIMENT_PATH/* -hl
else
    rm -rf $EXPERIMENT_PATH/*
    ls $EXPERIMENT_PATH/* -hl
fi

# prepare environment variables for Hermes
source $HOME/scripts/local-co-scheduling/load_hermes_deps.sh
source $HOME/scripts/local-co-scheduling/env_var.sh

mkdir -p $DEV1_DIR/hermes_slabs
mkdir -p $DEV2_DIR/hermes_swaps
rm -rf $DEV1_DIR/hermes_slabs/*
rm -rf $DEV2_DIR/hermes_swaps/*


list=()
while read -ra tmp; do
    list+=("${tmp[@]}")
done <<< "$NODE_NAMES"
hostlist=$(echo "$NODE_NAMES" | tr '\n' ',')
echo "hostlist: $hostlist"


# export TMPDIR=/scratch/$USER
# export OMP_NUM_THREADS=16

OPENMM () {

    task_id=$(seq -f "task%04g" $1 $1)
    gpu_idx=$(($1 % $GPU_PER_NODE))
    node_id=$2
    yaml_path=$3
    stage_name="molecular_dynamics"
    dest_path=$EXPERIMENT_PATH/${stage_name}_runs/$STAGE_IDX_FORMAT/$task_id

    if [ "$yaml_path" == "" ]
    then
        yaml_path=$DDMD_PATH/test/bba/${stage_name}_stage_test.yaml
    fi

    source activate hermes_openmm_ddmd

    mkdir -p $dest_path
    cd $dest_path
    echo "$gpu_idx $node_id cd $dest_path"

    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" -e "s/\$DDMD_PATH/${DDMD_PATH//\//\\/}/" -e "s/\$GPU_IDX/${gpu_idx}/" -e "s/\$STAGE_IDX/${STAGE_IDX}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)

    # # HERMES_STOP_DAEMON=0 HERMES_CLIENT=1 \ # srun -w $node_id -n1 -N1 --oversubscribe \
    ## --mpi=pmi2 
    set -x

    LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so:$LD_PRELOAD \
        HERMES_CONF=$HERMES_CONF \
        HERMES_CLIENT_CONF=$HERMES_CLIENT_CONF \
        PYTHONPATH=$DDMD_PATH:$MOLECULES_PATH \
        ~/anaconda3/envs/hermes_openmm_ddmd/bin/python $DDMD_PATH/deepdrivemd/sim/openmm/run_openmm.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log &

}


STOP_DAEMON() {
    echo "Stopping Hermes daemon"

    set -x
    mpirun --host $hostlist --pernode \
        -x LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        -x HERMES_CONF=$HERMES_CONF \
        -x HERMES_CLIENT_CONF=$HERMES_CLIENT_CONF \
        -x HERMES_STOP_DAEMON=1 \
        echo "finished"
    
    set +x
}


START_HERMES_DAEMON () {
    # --mca shmem_mmap_priority 80 \ \
    # -mca mca_verbose stdout 
    # -x UCX_NET_DEVICES=mlx5_0:1 \
    # -mca btl self -mca pml ucx \
    # -map-by node:PE=1 , --npernode 1 , --map-by ppr:1:node , --pernode

    echo "Starting hermes_daemon..."
    set -x

    mpirun --host $hostlist --npernode 1 \
        -x HERMES_CONF=$HERMES_CONF $HERMES_INSTALL_DIR/bin/hermes_daemon & #> ${FUNCNAME[0]}.log &

    sleep 5

    # check hermes devices
    ls -l $DEV1_DIR

    set +x
}

mpirun --host $hostlist --pernode killall hermes_daemon

hostname;date;
echo "Hermes Config : ADAPTER_MODE=$ADAPTER_MODE HERMES_PAGE_SIZE=$HERMES_PAGE_SIZE"

START_HERMES_DAEMON

(
total_start_time=$(($(date +%s%N)/1000000))

for iter in $(seq $ITER_COUNT)
do

    # STAGE 1: OpenMM
    
    if [ "$SKIP_OPENMM" == true ]
    then
        echo "OpenMM skipped... "
    else
        start_time=$(($(date +%s%N)/1000000))
        for node in $NODE_NAMES
        do
            while [ $MD_SLICE -gt 0 ] && [ $MD_START -lt $MD_RUNS ]
            do
                echo $node
                OPENMM $MD_START $node
                # srun -n1 -N1 --oversubscribe -w $node $( OPENMM $MD_START $node ) &
                MD_START=$(($MD_START + 1))
                MD_SLICE=$(($MD_SLICE - 1))
            done
            MD_SLICE=$(($MD_RUNS/$NODE_COUNT))
        done
        wait

        duration=$(( $(date +%s%N)/1000000 - $start_time))
        echo "OpenMM done... $duration milliseconds elapsed."
    fi

done

)


total_duration=$(( $(date +%s%N)/1000000 - $total_start_time))
echo "All done... $total_duration milliseconds elapsed."

hostname;date;

STOP_DAEMON

ls $EXPERIMENT_PATH/*/*/* -hl

sacct -j $SLURM_JOB_ID -o jobid,submit,start,end,state
rm -rf $SCRIPT_DIR/core.*