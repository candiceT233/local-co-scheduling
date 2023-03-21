#!/bin/bash
#SBATCH --job-name=hm_ddmd_n4t24i1_100ps_1
#SBATCH --partition=dlt
#SBATCH --exclude=dlt[02,06,10-12]
#SBATCH --account=chess
#SBATCH --time=02:30:00
#SBATCH -N 4
#SBATCH -n 24
#SBATCH --output=./R_%x.out                                        
#SBATCH --error=./R_%x.err

SKIP_OPENMM=false
SHORTENED_PIPELINE=true
MD_RUNS=24
ITER_COUNT=1 # TBD
SIM_LENGTH=0.1
SIZE=$(echo "$SIM_LENGTH * 1000" | bc)
SIZE=${SIZE%.*}
TRIAL=1
ADAPTER_MODE=$ADAPTERMODE

# EXPERIMENT_PATH=/rcfs/projects/chess/$USER/ddmd_runs/hermes_test_${SIZE}ps_i${ITER_COUNT} #PFS
EXPERIMENT_PATH=/qfs/projects/oddite/tang584/ddmd_runs/hermes_test_${SIZE}ps_i${ITER_COUNT}_${TRIAL} #NFS
DDMD_PATH=/people/$USER/scripts/deepdrivemd #NFS
MOLECULES_PATH=/qfs/projects/oddite/$USER/git/molecules #NFS
mkdir -p $EXPERIMENT_PATH

GPU_PER_NODE=6
MD_START=0
NODE_COUNT=$SLURM_JOB_NUM_NODES
MD_SLICE=$(($MD_RUNS/$NODE_COUNT))
STAGE_IDX=0
STAGE_IDX_FORMAT=$(seq -f "stage%04g" $STAGE_IDX $STAGE_IDX)

NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`

if [ "$SKIP_OPENMM" == true ]
then
    # keep molecular_dynamics_runs
    rm -rf $EXPERIMENT_PATH/agent_runs
    rm -rf $EXPERIMENT_PATH/inference_runs
    rm -rf $EXPERIMENT_PATH/machine_learning_runs
    rm -rf $EXPERIMENT_PATH/model_selection_runs
    ls $EXPERIMENT_PATH/* -hl
else
    rm -rf $EXPERIMENT_PATH/*
    ls $EXPERIMENT_PATH/* -hl
fi
# OPENMM_PYTHON=~/.conda/envs/hm_ddmd_openmm_deception/bin/python
# PYTORCH_PYTHON=~/.conda/envs/hm_ddmd_pytorch_deception/bin/python

module purge
module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh

# load environment variables for Hermes
ulimit -c unlimited
# . $HOME/zen2_dec/dec_spack/share/spack/setup-env.sh
source $HOME/scripts/local-co-scheduling/load_hermes_deps.sh
source $HOME/scripts/local-co-scheduling/env_var.sh

mkdir -p $DEV1_DIR/hermes_slabs
mkdir -p $DEV2_DIR/hermes_swaps
rm -rf $DEV1_DIR/hermes_slabs/*
rm -rf $DEV2_DIR/hermes_swaps/*

NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`
# hostlist=$(echo -e "$NODE_NAMES" | xargs | sed -e 's/ /,/g')
# echo "hostlist=$hostlist"

> ./host_ip
for node in $NODE_NAMES
do
    # "$node.ibnet:1"
    # grep "$node.local" /etc/hosts | awk '{print $1}' >> ./host_ip
    echo "$node.ibnet:1" >> ./host_ip
done
cat ./host_ip
hostlist=$(cat ./host_ip | xargs | sed -e 's/ /,/g')
echo "hostlist=$hostlist"

# IFS=',' read -r -a NODE_ARR <<< "$hostlist"
# echo "TRAINING on = ${NODE_ARR[0]}"
# echo "INFERENCE on = ${NODE_ARR[1]}"

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

    # module purge
    # module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
    # source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh
    source activate hm_ddmd_openmm_deception

    mkdir -p $dest_path
    cd $dest_path
    echo "$gpu_idx $node_id cd $dest_path"

    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" -e "s/\$DDMD_PATH/${DDMD_PATH//\//\\/}/" -e "s/\$GPU_IDX/${gpu_idx}/" -e "s/\$STAGE_IDX/${STAGE_IDX}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)

    # # HERMES_STOP_DAEMON=0 HERMES_CLIENT=1 \ #must have --oversubscribe --exclusive
    ## --mpi=pmi2 

    LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so:$LD_PRELOAD \
        HERMES_CONF=$HERMES_CONF \
        HERMES_CLIENT_CONF=$HERMES_CLIENT_CONF \
        PYTHONPATH=$DDMD_PATH:$MOLECULES_PATH \
        srun -w $node_id -n1 -N1 --oversubscribe --mpi=pmi2 \
        ~/.conda/envs/hm_ddmd_openmm_deception/bin/python $DDMD_PATH/deepdrivemd/sim/openmm/run_openmm.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log &

    # srun -w $node_id -N1 --oversubscribe \
    #     ~/.conda/envs/hm_ddmd_openmm_deception/bin/python $DDMD_PATH/deepdrivemd/sim/openmm/run_openmm.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log &


    #PYTHONPATH=~/git/molecules/ srun -w $node_id -N1 python /people/leeh736/git/DeepDriveMD-pipeline/deepdrivemd/sim/openmm/run_openmm.py -c $yaml_path &>> $task_id.log &
    #srun -n1 env LD_PRELOAD=~/git/tazer_forked/build.h5/src/client/libclient.so PYTHONPATH=~/git/molecules/ python /people/leeh736/git/DeepDriveMD-pipeline/deepdrivemd/sim/openmm/run_openmm.py -c /qfs/projects/oddite/leeh736/ddmd_runs/test/md_direct.yaml &> $task_id.log &
}

AGGREGATE () {

    task_id=task0000
    stage_name="aggregate"
    STAGE_IDX=$(($STAGE_IDX - 1))
    STAGE_IDX_FORMAT=$(seq -f "stage%04g" $STAGE_IDX $STAGE_IDX)
    dest_path=$EXPERIMENT_PATH/molecular_dynamics_runs/$STAGE_IDX_FORMAT/$task_id
    yaml_path=$DDMD_PATH/test/bba/${stage_name}_stage_test.yaml

    source activate hm_ddmd_openmm_deception
    mkdir -p $dest_path
    cd $dest_path
    echo cd $dest_path


    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" -e "s/\$STAGE_IDX/${STAGE_IDX}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)

    LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
    HERMES_CONF=$HERMES_CONF \
    ADAPTER_MODE=$ADAPTER_MODE \
    HERMES_STOP_DAEMON=0 \
    HERMES_CLIENT=1 \
    ~/.conda/envs/hm_ddmd_openmm_deception/bin/python $DDMD_PATH/deepdrivemd/aggregation/basic/aggregate.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log

    # { time PYTHONPATH=$DDMD_PATH/ ~/.conda/envs/hm_ddmd_openmm_deception/bin/python $DDMD_PATH/deepdrivemd/aggregation/basic/aggregate.py -c $yaml_path ; } &> ${task_id}_${FUNCNAME[0]}.log
    #env LD_PRELOAD=/qfs/people/leeh736/git/tazer_forked/build.h5.pread64.bluesky/src/client/libclient.so PYTHONPATH=$DDMD_PATH/ python /files0/oddite/deepdrivemd/src/deepdrivemd/aggregation/basic/aggregate.py -c /qfs/projects/oddite/leeh736/ddmd_runs/1k/agg_test.yaml &> agg_test_output.log
}


TRAINING () {

    task_id=task0000
    stage_name="machine_learning"
    dest_path=$EXPERIMENT_PATH/${stage_name}_runs/$STAGE_IDX_FORMAT/$task_id
    stage_name="training"
    yaml_path=$DDMD_PATH/test/bba/${stage_name}_stage_test.yaml

    mkdir -p $EXPERIMENT_PATH/model_selection_runs/$STAGE_IDX_FORMAT/$task_id/
    cp -p $DDMD_PATH/test/bba/stage0000_$task_id.json $EXPERIMENT_PATH/model_selection_runs/$STAGE_IDX_FORMAT/$task_id/${STAGE_IDX_FORMAT}_$task_id.json

    source activate hm_ddmd_pytorch_deception
    mkdir -p $dest_path
    cd $dest_path
    echo cd $dest_path

    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" -e "s/\$STAGE_IDX/${STAGE_IDX}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)
    
    # PYTHONPATH=$DDMD_PATH/:$MOLECULES_PATH ~/.conda/envs/hm_ddmd_pytorch_deception/bin/python $DDMD_PATH/deepdrivemd/models/aae/train.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log 
    echo PYTHONPATH=$DDMD_PATH/:$MOLECULES_PATH ~/.conda/envs/hm_ddmd_pytorch_deception/bin/python $DDMD_PATH/deepdrivemd/models/aae/train.py -c $yaml_path ${task_id}_${FUNCNAME[0]}.log 

    # HERMES_TRAINING_STAGEIN

    if [ "$SHORTENED_PIPELINE" == true ]
    then
        LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so:$LD_PRELOAD \
            HERMES_CONF=$HERMES_CONF \
            HERMES_CLIENT_CONF=$HERMES_CLIENT_CONF \
            OMP_NUM_THREADS=16 \
            PYTHONPATH=$DDMD_PATH:$MOLECULES_PATH \
            srun -N1 --oversubscribe --mpi=pmi2 -n1 \
            ~/.conda/envs/hm_ddmd_pytorch_deception/bin/python $DDMD_PATH/deepdrivemd/models/aae/train.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log &
    else
        LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so:$LD_PRELOAD \
            HERMES_CONF=$HERMES_CONF \
            HERMES_CLIENT_CONF=$HERMES_CLIENT_CONF \
            OMP_NUM_THREADS=16 \
            PYTHONPATH=$DDMD_PATH:$MOLECULES_PATH \
            srun -N1 --oversubscribe --mpi=pmi2 -n1 \
            ~/.conda/envs/hm_ddmd_pytorch_deception/bin/python $DDMD_PATH/deepdrivemd/models/aae/train.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log
    fi

}

INFERENCE () {

    task_id=task0000
    stage_name="inference"
    dest_path=$EXPERIMENT_PATH/${stage_name}_runs/$STAGE_IDX_FORMAT/$task_id
    yaml_path=$DDMD_PATH/test/bba/${stage_name}_stage_test.yaml
    pretrained_model=$DDMD_PATH/data/bba/epoch-130-20201203-150026.pt

    source activate hm_ddmd_pytorch_deception
    mkdir -p $dest_path
    cd $dest_path
    echo cd $dest_path

    mkdir -p $EXPERIMENT_PATH/agent_runs/$STAGE_IDX_FORMAT/$task_id/

    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" -e "s/\$STAGE_IDX/${STAGE_IDX}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)
    
    # latest model search
    model_checkpoint=$(find $EXPERIMENT_PATH/machine_learning_runs/*/*/checkpoint -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")
    if [ "$model_checkpoint" == "" ] && [ "$SHORTENED_PIPELINE" == true ]
    then
        model_checkpoint=$pretrained_model
    fi
    STAGE_IDX_PREV=$((STAGE_IDX - 1))
    STAGE_IDX_FORMAT_PREV=$(seq -f "stage%04g" $STAGE_IDX_PREV $STAGE_IDX_PREV)

    sed -i -e "s/\$MODEL_CHECKPOINT/${model_checkpoint//\//\\/}/"  $EXPERIMENT_PATH/model_selection_runs/$STAGE_IDX_FORMAT_PREV/task0000/${STAGE_IDX_FORMAT_PREV}_task0000.json

    # mpirun -n 2 $HERMES_INSTALL_DIR/bin/stage_in $EXPERIMENT_PATH/model_selection_runs/$STAGE_IDX_FORMAT_PREV 0 0 MinimizeIoTime

    LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so:$LD_PRELOAD \
        HERMES_CONF=$HERMES_CONF \
        HERMES_CLIENT_CONF=$HERMES_CLIENT_CONF \
        OMP_NUM_THREADS=4 \
        PYTHONPATH=$DDMD_PATH/:$MOLECULES_PATH \
        ~/.conda/envs/hm_ddmd_pytorch_deception/bin/python $DDMD_PATH/deepdrivemd/agents/lof/lof.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log 

}

STAGE_UPDATE() {

    STAGE_IDX=$(($STAGE_IDX + 1))
    tmp=$(seq -f "stage%04g" $STAGE_IDX $STAGE_IDX)
    echo $tmp
}

HERMES_TRAINING_STAGEIN (){
    start_time=$SECONDS
    # # data stage_in
    # STAGE_PROCS=1
    # ALL_PPROCS=$(( $STAGE_PROCS * $NODE_COUNT ))
    set -x
    # mpirun -np $ALL_PPROCS -ppn $STAGE_PROCS -host $hostlist \
    #     $HERMES_INSTALL_DIR/bin/stage_in $EXPERIMENT_PATH/model_selection_runs/$STAGE_IDX_FORMAT 0 0 MinimizeIoTime
    $HERMES_INSTALL_DIR/bin/stage_in $EXPERIMENT_PATH/model_selection_runs/$STAGE_IDX_FORMAT 0 0 MinimizeIoTime
    set +x
    duration=$(($SECONDS - $start_time))
    echo "Training Data stage_in... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed ($duration secs)."
    # mpirun -n $STAGE_PROCS $HERMES_INSTALL_DIR/bin/stage_in $HERMES_SCRIPT/ALL.chr1.250000.vcf 0 0 MinimizeIoTime

}

STOP_DAEMON() {

    mpirun --host $hostlist --pernode \
        -x LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        -x HERMES_CONF=$HERMES_CONF \
        -x ADAPTER_MODE=$ADAPTER_MODE \
        -x HERMES_STOP_DAEMON=1 \
        -x HERMES_CLIENT=1 \
        echo "finished"
}

HERMES_LOCAL_CONFIG () {
    sed "s/\$HOST_BASE_NAME/\"localhost\"/" $HERMES_DEFAULT_CONF  > $HERMES_CONF
    sed -i "s/\$HOST_NUMBER_RANGE/ /" $HERMES_CONF
}

HERMES_DIS_CONFIG () {

    prefix="dlt0"
    sed "s/\$HOST_BASE_NAME/\"${prefix}\"/" $HERMES_DEFAULT_CONF  > $HERMES_CONF

    node_range=()
    while read -r node; do
        node_range+=("${node//${prefix}/}")
    done <<< "$NODE_NAMES"
    rpc_host_number_range="[$(printf "%s," "${node_range[@]}" | sed 's/,$//')]"
    
    echo "node_range=${node_range[@]}"
    echo "rpc_host_number_range=$rpc_host_number_range"
    sed -i "s/\$HOST_NUMBER_RANGE/${rpc_host_number_range}/" $HERMES_CONF

    echo "$NODE_NAMES" | sed 's/$/.ibnet/' > $SCRIPT_DIR/host_ip
}

START_HERMES_DAEMON () {
    # --mca shmem_sysv_priority 100 \

    echo "Starting hermes_daemon..."
    set -x
    # -map-by node:PE=1 , --npernode 1 , --map-by ppr:1:node , --pernode
    
    # mpirun --host $hostlist --npernode 1 \
    #     -x HERMES_CONF=$HERMES_CONF $HERMES_INSTALL_DIR/bin/hermes_daemon &

    mpirun --host $hostlist --pernode --verbose \
        -x HERMES_CONF=$HERMES_CONF $HERMES_INSTALL_DIR/bin/hermes_daemon &> ${FUNCNAME[0]}.log &

    sleep 5
    echo ls -l $DEV1_DIR/hermes_slabs
    ls -l $DEV1_DIR/hermes_slabs
    set +x
}

# get nodelist to hermes config file
# if [ "$NODE_COUNT" = "1" ]; then
#     HERMES_LOCAL_CONFIG
# else
#     HERMES_DIS_CONFIG
# fi

mpirun --host $hostlist --pernode killall hermes_daemon

hostname;date;
echo "Hermes Config : ADAPTER_MODE=$ADAPTER_MODE HERMES_PAGE_SIZE=$HERMES_PAGE_SIZE"

HERMES_DIS_CONFIG
START_HERMES_DAEMON

total_start_time=$SECONDS

# (
# for iter in $(seq $ITER_COUNT)
# do
#         # STAGE 1: OpenMM
#         start_time=$SECONDS

#         if [ "$SKIP_OPENMM" != true ]
#         then
#             for node in $NODE_NAMES
#             do
#                 while [ $MD_SLICE -gt 0 ] && [ $MD_START -lt $MD_RUNS ]
#                 do
#                     echo $node
#                     OPENMM $MD_START $node
#                     # srun -w $node -n1 -N1 --oversubscribe $( OPENMM $MD_START $node ) &
#                     MD_START=$(($MD_START + 1))
#                     MD_SLICE=$(($MD_SLICE - 1))
#                 done
#                 MD_SLICE=$(($MD_RUNS/$NODE_COUNT))
#             done
#         else
#             echo "OpenMM Skipped ---"
#         fi
#         wait
#         MD_START=0
#         duration=$(($SECONDS - $start_time))
#         echo "OpenMM done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed ($duration secs)."

        
#         STAGE_IDX_FORMAT="$(STAGE_UPDATE)"
#         STAGE_IDX=$((STAGE_IDX + 1))
#         echo $STAGE_IDX_FORMAT
        

#         # STAGE 2: Aggregate
#         if [ "$SHORTENED_PIPELINE" != true ]
#         then
#             start_time=$SECONDS
#             srun -N1 $( AGGREGATE )
#             wait 
#             duration=$(($SECONDS - $start_time))
#             echo "Aggregate done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed ($duration secs)."
#         else
#             echo "No AGGREGATE, SHORTENED_PIPELINE = $SHORTENED_PIPELINE..."
#         fi
        
#         STAGE_IDX_FORMAT="$(STAGE_UPDATE)"
#         STAGE_IDX=$((STAGE_IDX + 1))
#         echo $STAGE_IDX_FORMAT

#         # STAGE 3: Training
#         # srun -n1 -N1 --oversubscribe $( TRAINING ) &
#         TRAINING

#         start_time=$SECONDS
#         if [ "$SHORTENED_PIPELINE" != true ]
#         then
#             wait
#             duration=$(($SECONDS - $start_time))
#             echo "Training done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed ($duration secs)."
#         else
#             echo "Training not waited, SHORTENED_PIPELINE = $SHORTENED_PIPELINE..."
#         fi

#         STAGE_IDX_FORMAT="$(STAGE_UPDATE)"
#         STAGE_IDX=$((STAGE_IDX + 1))
#         echo $STAGE_IDX_FORMAT $STAGE_IDX

#         # STAGE 4: Inference -w ${NODE_ARR[1]} 
#         start_time=$SECONDS
#         srun -N1 --oversubscribe --mpi=pmi2 -n1 $( INFERENCE )
#         wait
        
#         duration=$(($SECONDS - $start_time))
#         echo "Inference done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed ($duration secs)."

#         STAGE_IDX_FORMAT="$(STAGE_UPDATE)"
#         STAGE_IDX=$((STAGE_IDX + 1))
#         echo $STAGE_IDX_FORMAT

# done
# )


total_duration=$(($SECONDS - $total_start_time))
echo "All done... $(($total_duration / 60)) minutes and $(($total_duration % 60)) seconds elapsed ($total_duration secs)."


hostname;date;
# set -x
# mpirun -np $NODE_COUNT -ppn 1 -host $hostlist -x HERMES_CONF=${HERMES_CONF} ${HERMES_INSTALL_DIR}/bin/finalize_hermes
# set +x

STOP_DAEMON
# wait

ls $EXPERIMENT_PATH/*/*/* -hl

sacct -j $SLURM_JOB_ID -o jobid,submit,start,end,state
rm -rf $SCRIPT_DIR/core.*

# --output=R_%x.%j.out --exclude=dlt[06]
# --nodelist=a100-[03-06] --exclude=a100-[01-02]