#!/bin/bash
#SBATCH --job-name=2hm_sc_ddmd_n2t24i1_100ps
#SBATCH --partition=a100
#SBATCH --account=chess
#SBATCH --time=02:30:00
#SBATCH -N 2
#SBATCH -n 12
#SBATCH --output=R_%x.out                                        
#SBATCH --error=R_%x.err

SKIP_OPENMM=false
SHORTENED_PIPELINE=true
MD_RUNS=12
ITER_COUNT=1 # TBD
SIM_LENGTH=0.01

NODE_COUNT=$SLURM_JOB_NUM_NODES
GPU_PER_NODE=6
MD_START=0
MD_SLICE=$(($MD_RUNS/$NODE_COUNT))
NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`
STAGE_IDX=0
STAGE_IDX_FORMAT=$(seq -f "stage%04g" $STAGE_IDX $STAGE_IDX)
ADAPTER_MODE="SCRATCH"

# EXPERIMENT_PATH=/qfs/projects/oddite/tang584/ddmd_runs/hermes_test_100ps #NFS
EXPERIMENT_PATH=/files0/oddite/tang584/ddmd_runs/2hermes_test_100ps #PFS
DDMD_PATH=/people/tang584/scripts/deepdrivemd #NFS
MOLECULES_PATH=/qfs/projects/oddite/tang584/git/molecules #NFS


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
# OPENMM_PYTHON=~/.conda/envs/hermes_openmm_ddmd/bin/python
# PYTORCH_PYTHON=~/.conda/envs/hermes_pytorch_ddmd/bin/python

module purge
module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 
#openmpi/4.1.3
source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh
# conda activate hermes_ddmd #/files0/oddite/conda/ddmd/

# load environment variables for Hermes
ulimit -c unlimited
. /qfs/people/tang584/zen2_dec/dec_spack/share/spack/setup-env.sh
source /qfs/people/tang584/scripts/local-co-scheduling/load_hermes_deps.sh
source /qfs/people/tang584/scripts/local-co-scheduling/env_var.sh

mkdir -p $DEV1_DIR/hermes_slabs
mkdir -p $DEV2_DIR/hermes_swaps
rm -rf $DEV1_DIR/hermes_slabs/*
rm -rf $DEV2_DIR/hermes_swaps/*

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
echo "hostlist=$hostlist"


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
    echo cd $dest_path


    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" -e "s/\$DDMD_PATH/${DDMD_PATH//\//\\/}/" -e "s/\$GPU_IDX/${gpu_idx}/" -e "s/\$STAGE_IDX/${STAGE_IDX}/" $yaml_path  > $dest_path/$(basename $yaml_path)

    yaml_path=$dest_path/$(basename $yaml_path)

    # export LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so
    # export HERMES_CONF=$HERMES_CONF
    # export HERMES_CLIENT_CONF=$HERMES_CLIENT_CONF

    # PYTHONPATH=$DDMD_PATH:$MOLECULES_PATH srun -w $node_id -n1 -N1 --exclusive \
    #     mpirun -np 1 \
    #     -genv LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
    #     -genv HERMES_CONF=$HERMES_CONF \
    #     -genv ADAPTER_MODE=$ADAPTER_MODE \
    #     -genv HERMES_STOP_DAEMON=0 \
    #     -genv HERMES_CLIENT=1 \
    #     ~/.conda/envs/hermes_openmm_ddmd/bin/python $DDMD_PATH/deepdrivemd/sim/openmm/run_openmm.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log &

    PYTHONPATH=$DDMD_PATH:$MOLECULES_PATH srun -w $node_id -n1 -N1 --exclusive \
        mpirun -np 1 \
        -genv LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        -genv HERMES_CONF=$HERMES_CONF \
        -genv HERMES_CLIENT_CONF=$HERMES_CLIENT_CONF \
        ~/.conda/envs/hermes_openmm_ddmd/bin/python $DDMD_PATH/deepdrivemd/sim/openmm/run_openmm.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log &

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

    source activate hermes_openmm_ddmd
    mkdir -p $dest_path
    cd $dest_path
    echo cd $dest_path


    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" -e "s/\$STAGE_IDX/${STAGE_IDX}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)

    mpirun -np 1 \
        -genv LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        -genv HERMES_CONF=$HERMES_CONF \
        -genv ADAPTER_MODE=$ADAPTER_MODE \
        -genv HERMES_STOP_DAEMON=0 \
        -genv HERMES_CLIENT=1 \
    ~/.conda/envs/hermes_openmm_ddmd/bin/python $DDMD_PATH/deepdrivemd/aggregation/basic/aggregate.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log

    # { time PYTHONPATH=$DDMD_PATH/ ~/.conda/envs/hermes_openmm_ddmd/bin/python $DDMD_PATH/deepdrivemd/aggregation/basic/aggregate.py -c $yaml_path ; } &> ${task_id}_${FUNCNAME[0]}.log
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

    source activate hermes_pytorch_ddmd
    mkdir -p $dest_path
    cd $dest_path
    echo cd $dest_path


    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" -e "s/\$STAGE_IDX/${STAGE_IDX}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)
    
    # PYTHONPATH=$DDMD_PATH/:$MOLECULES_PATH ~/.conda/envs/hermes_pytorch_ddmd/bin/python $DDMD_PATH/deepdrivemd/models/aae/train.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log 
    echo PYTHONPATH=$DDMD_PATH/:$MOLECULES_PATH srun -n1 -N1 --exclusive ~/.conda/envs/hermes_pytorch_ddmd/bin/python $DDMD_PATH/deepdrivemd/models/aae/train.py -c $yaml_path ${task_id}_${FUNCNAME[0]}.log 
    if [ "$SHORTENED_PIPELINE" == true ]
    then
        PYTHONPATH=$DDMD_PATH/:$MOLECULES_PATH srun -n1 -N1 --exclusive \
            mpirun -np 1 \
            -genv LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
            -genv HERMES_CONF=$HERMES_CONF \
            -genv ADAPTER_MODE=$ADAPTER_MODE \
            -genv HERMES_STOP_DAEMON=0 \
            -genv HERMES_CLIENT=1 \
            ~/.conda/envs/hermes_pytorch_ddmd/bin/python $DDMD_PATH/deepdrivemd/models/aae/train.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log &
    else
        PYTHONPATH=$DDMD_PATH/:$MOLECULES_PATH srun -n1 -N1 --exclusive \
            mpirun -np 1 \
            -genv LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
            -genv HERMES_CONF=$HERMES_CONF \
            -genv ADAPTER_MODE=$ADAPTER_MODE \
            -genv HERMES_STOP_DAEMON=0 \
            -genv HERMES_CLIENT=1 \
            ~/.conda/envs/hermes_pytorch_ddmd/bin/python $DDMD_PATH/deepdrivemd/models/aae/train.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log
    fi

}

INFERENCE () {

    task_id=task0000
    stage_name="inference"
    dest_path=$EXPERIMENT_PATH/${stage_name}_runs/$STAGE_IDX_FORMAT/$task_id
    yaml_path=$DDMD_PATH/test/bba/${stage_name}_stage_test.yaml
    pretrained_model=$DDMD_PATH/data/bba/epoch-130-20201203-150026.pt

    source activate hermes_pytorch_ddmd
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


    OMP_NUM_THREADS=4 PYTHONPATH=$DDMD_PATH/:$MOLECULES_PATH \
        mpirun -np 1 \
        -genv LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        -genv HERMES_CONF=$HERMES_CONF \
        -genv ADAPTER_MODE= \
        -genv HERMES_STOP_DAEMON=0 \
        -genv HERMES_CLIENT=1 \
        ~/.conda/envs/hermes_pytorch_ddmd/bin/python $DDMD_PATH/deepdrivemd/agents/lof/lof.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log 

}
#

# Python environment on Bluesky
# module load python/miniconda3.7 gcc/9.1.0
# source activate openmm

# set -x

STAGE_UPDATE() {

    STAGE_IDX=$(($STAGE_IDX + 1))
    tmp=$(seq -f "stage%04g" $STAGE_IDX $STAGE_IDX)
    echo $tmp
}

HERMES_TRAINING_STAGEIN (){
    # data stage_in
    STAGE_PROCS=1
    ALL_PPROCS=$(( $STAGE_PROCS * $NODE_COUNT ))
    mpirun -np $ALL_PPROCS -ppn $STAGE_PROCS -host $hostlist \
        $HERMES_INSTALL_DIR/bin/stage_in $EXPERIMENT_PATH/molecular_dynamics_runs 0 0 MinimizeIoTime

    # mpirun -n $STAGE_PROCS $HERMES_INSTALL_DIR/bin/stage_in $HERMES_SCRIPT/ALL.chr1.250000.vcf 0 0 MinimizeIoTime
}

STOP_DAEMON() {

    mpirun -np $NODE_COUNT -ppn 1 -host $hostlist \
        -genv LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        -genv HERMES_CONF=$HERMES_CONF \
        -genv ADAPTER_MODE=$ADAPTER_MODE \
        -genv HERMES_STOP_DAEMON=1 \
        -genv HERMES_CLIENT=1 \
        echo "finished"
}

hostname;date;
echo "Hermes Config : ADAPTER_MODE=$ADAPTER_MODE HERMES_PAGESIZE=$HERMES_PAGESIZE"

set -x
mpirun -np $NODE_COUNT -ppn 1 -host $hostlist killall hermes_daemon
mpirun -np $NODE_COUNT -ppn 1 -host $hostlist -genv HERMES_CONF=$HERMES_CONF $HERMES_INSTALL_DIR/bin/hermes_daemon &
sleep 6
# ls -l /state/partition1/tang584/hermes_slabs
set +x

total_start_time=$SECONDS

(
for iter in $(seq $ITER_COUNT)
do

        # STAGE 1: OpenMM
        start_time=$SECONDS

        if [ "$SKIP_OPENMM" != true ]
        then
            for node in $NODE_NAMES
            do
                while [ $MD_SLICE -gt 0 ] && [ $MD_START -lt $MD_RUNS ]
                do
                    echo $node
                    OPENMM $MD_START $node
                    MD_START=$(($MD_START + 1))
                    MD_SLICE=$(($MD_SLICE - 1))
                done
                MD_SLICE=$(($MD_RUNS/$NODE_COUNT))
            done
        else
            echo "OpenMM Skipped ---"
        fi
        wait

        MD_START=0

        duration=$(($SECONDS - $start_time))
        echo "OpenMM done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed ($duration secs)."

        STAGE_IDX_FORMAT="$(STAGE_UPDATE)"
        STAGE_IDX=$((STAGE_IDX + 1))
        echo $STAGE_IDX_FORMAT

        # STAGE 2: Aggregate
        if [ "$SHORTENED_PIPELINE" != true ]
        then
            start_time=$SECONDS
            srun -N1 $( AGGREGATE )
            wait 
            duration=$(($SECONDS - $start_time))
            echo "Aggregate done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed ($duration secs)."
        else
            echo "No AGGREGATE, SHORTENED_PIPELINE = $SHORTENED_PIPELINE..."
        fi
        
        wait
        
        STAGE_IDX_FORMAT="$(STAGE_UPDATE)"
        STAGE_IDX=$((STAGE_IDX + 1))
        echo $STAGE_IDX_FORMAT

        # STAGE 3: Training
        start_time=$SECONDS
        TRAINING

        STAGE_IDX_FORMAT="$(STAGE_UPDATE)"
        STAGE_IDX=$((STAGE_IDX + 1))
        echo $STAGE_IDX_FORMAT $STAGE_IDX
        if [ "$SHORTENED_PIPELINE" != true ]
        then
            wait
            duration=$(($SECONDS - $start_time))
            echo "Training done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed ($duration secs)."
        else
            echo "Training not waited, SHORTENED_PIPELINE = $SHORTENED_PIPELINE..."
        fi

        # STAGE 4: Inference
        start_time=$SECONDS
        srun $( INFERENCE )
        wait
        duration=$(($SECONDS - $start_time))
        echo "Inference done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed ($duration secs)."

        STAGE_IDX_FORMAT="$(STAGE_UPDATE)"
        STAGE_IDX=$((STAGE_IDX + 1))
        echo $STAGE_IDX_FORMAT

done
)

total_duration=$(($SECONDS - $total_start_time))
echo "All done... $(($total_duration / 60)) minutes and $(($total_duration % 60)) seconds elapsed ($total_duration secs)."

hostname;date;

set -x
mpirun -np $NODE_COUNT -ppn 1 -host $hostlist -genv HERMES_CONF=${HERMES_CONF} ${HERMES_INSTALL_DIR}/bin/finalize_hermes
set +x

STOP_DAEMON
# wait

ls $EXPERIMENT_PATH/molecular_dynamics_runs/*/* -hl
ls $EXPERIMENT_PATH/machine_learning_runs/*/* -hl
ls $EXPERIMENT_PATH/inference_runs/*/* -hl


sacct -j $SLURM_JOB_ID -o jobid,submit,start,end,state
rm -rf $SCRIPT_DI/core.*