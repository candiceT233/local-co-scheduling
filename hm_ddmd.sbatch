#!/bin/bash
#SBATCH --job-name=hm_deepdrivemd
#SBATCH --account=oddite
#SBATCH --time=01:30:00
#SBATCH -N 4
#SBATCH -n 18
#SBATCH  --exclude=node[01-25]
#SBATCH --output=R_%x.out                                        
#SBATCH --error=R_%x.err

# --output=R_%x.%j.out --nodelist=node[36,43]

MD_RUNS=12
ITER_COUNT=1 # TBD
SIM_LENGTH=0.1 #1.6
STAGE_IDX=0
NODE_COUNT=$SLURM_JOB_NUM_NODES


module purge
module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 #openmpi/4.1.3
source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh

ulimit -c unlimited
. $HOME/spack/share/spack/setup-env.sh
source /qfs/people/tang584/scripts/local-co-scheduling/load_hermes_deps.sh

# load environment variables for Hermes
source /qfs/people/tang584/scripts/local-co-scheduling/env_var.sh 
# source /qfs/people/tang584/scripts/local-co-scheduling/load_hermes_deps.sh
# export GLOG_minloglevel=0
# export FLAGS_logtostderr=0

# conda activate hermes_ddmd #/files0/oddite/conda/ddmd/
# source /qfs/people/tang584/scripts/local-co-scheduling/venv_ddmd/bin/activate

GPU_PER_NODE=6
MD_START=0
MD_SLICE=$(($MD_RUNS/$NODE_COUNT))

# get nodelist to hermes config file
if [ "$NODE_COUNT" = "1" ]; then
    sed "s/\$HOST_BASE_NAME/\"localhost\"/" $HERMES_DEFAULT_CONF  > $HERMES_CONF
    sed -i "s/\$HOST_NUMBER_RANGE/ /" $HERMES_CONF
else
    sed "s/\$HOST_BASE_NAME/\"node\"/" $HERMES_DEFAULT_CONF  > $HERMES_CONF
    rpc_host_number_range=$(echo "$SLURM_JOB_NODELIST" | grep -Po '[\[].*[\]]')
    sed -i "s/\$HOST_NUMBER_RANGE/${rpc_host_number_range}/" $HERMES_CONF
fi

# OPENMM_PYTHON=~/.conda/envs/hermes_openmm_ddmd/bin/python
# PYTORCH_PYTHON=~/.conda/envs/hermes_pytorch_ddmd/bin/python
NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`
hostlist=$(echo -e "$NODE_NAMES" | xargs | sed -e 's/ /,/g')
echo "hostlist=$hostlist"


# set -x
# setup  dir
EXPERIMENT_PATH=/qfs/projects/oddite/tang584/ddmd_runs/hermes_test_100ps
DDMD_PATH=/people/tang584/scripts/deepdrivemd
MOLECULES_PATH=/qfs/projects/oddite/tang584/git/molecules

mkdir -p $DEV1_DIR/hermes_slabs
mkdir -p $DEV2_DIR/hermes_swaps
# mkdir -p $DEV3_DIR

rm -rf $DEV1_DIR/hermes_slabs/*
rm -rf $DEV2_DIR/hermes_swaps/*
rm -rf $EXPERIMENT_PATH/*
ls $EXPERIMENT_PATH/* -hl


OPENMM () {

    task_id=$(seq -f "task%04g" $1 $1)
    gpu_idx=$(($1 % $GPU_PER_NODE))
    node_id=$2
    yaml_path=$3
    stage_name="molecular_dynamics"
    dest_path=$EXPERIMENT_PATH/${stage_name}_runs/stage0000/$task_id

    if [ "$yaml_path" == "" ]
    then
        yaml_path=$DDMD_PATH/test/bba/${stage_name}_stage_test.yaml
    fi

    source activate hermes_openmm_ddmd
    # source /qfs/people/tang584/scripts/local-co-scheduling/load_hermes_deps.sh

    mkdir -p $dest_path
    cd $dest_path
    # echo cd $dest_path
    echo "$node_id $dest_path"

    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" -e "s/\$DDMD_PATH/${DDMD_PATH//\//\\/}/" -e "s/\$GPU_IDX/${gpu_idx}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)
    # cat $yaml_path

    PYTHONPATH=$DDMD_PATH:$MOLECULES_PATH srun -w $node_id -n1 -N1 --exclusive \
        mpirun -np 1 \
        -genv LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/libhermes_posix.so \
        -genv HERMES_CONF=${HERMES_CONF} \
        -genv ADAPTER_MODE=SCRATCH \
        -genv HERMES_STOP_DAEMON=0 \
        -genv HERMES_CLIENT=1 \
        ~/.conda/envs/hermes_openmm_ddmd/bin/python $DDMD_PATH/deepdrivemd/sim/openmm/run_openmm.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log &

    #PYTHONPATH=~/git/molecules/ srun -w $node_id -N1 python /people/leeh736/git/DeepDriveMD-pipeline/deepdrivemd/sim/openmm/run_openmm.py -c $yaml_path &>> $task_id.log &
    #srun -n1 env LD_PRELOAD=~/git/tazer_forked/build.h5/src/client/libclient.so PYTHONPATH=~/git/molecules/ python /people/leeh736/git/DeepDriveMD-pipeline/deepdrivemd/sim/openmm/run_openmm.py -c /qfs/projects/oddite/leeh736/ddmd_runs/test/md_direct.yaml &> $task_id.log &
}

AGGREGATE () {

    task_id=task0000
    stage_name="aggregate"
    dest_path=$EXPERIMENT_PATH/molecular_dynamics_runs/stage0000/$task_id
    yaml_path=$DDMD_PATH/test/bba/${stage_name}_stage_test.yaml

    source activate hermes_openmm_ddmd
    mkdir -p $dest_path
    cd $dest_path
    echo cd $dest_path

    sed -e "s/\$STAGE_IDX/${STAGE_IDX}/" -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)

    # export PYTHONPATH=$DDMD_PATH:$MOLECULES_PATH
    # export LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so
    # export HERMES_CONF=$HERMES_CONF
    # export ADAPTER_MODE=SCRATCH
    # export HERMES_STOP_DAEMON=1
    # export HERMES_CLIENT=1
    # export LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so
    # export HERMES_CONF=$HERMES_CONF
    # export ADAPTER_MODE=SCRATCH
    # export HERMES_STOP_DAEMON=1
    # export HERMES_CLIENT=1

    mpirun -np 1 \
        -genv LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/libhermes_posix.so \
        -genv HERMES_CONF=${HERMES_CONF} \
        -genv ADAPTER_MODE=SCRATCH \
        -genv HERMES_STOP_DAEMON=0 \
        -genv HERMES_CLIENT=1 \
        ~/.conda/envs/hermes_openmm_ddmd/bin/python $DDMD_PATH/deepdrivemd/aggregation/basic/aggregate.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log

    # { time PYTHONPATH=$DDMD_PATH/ ~/.conda/envs/hermes_openmm_ddmd/bin/python $DDMD_PATH/deepdrivemd/aggregation/basic/aggregate.py -c $yaml_path ; } &> ${task_id}_${FUNCNAME[0]}.log 
    
    #env LD_PRELOAD=/qfs/people/leeh736/git/tazer_forked/build.h5.pread64.bluesky/src/client/libclient.so PYTHONPATH=~/git/deepdrivemd/ python /files0/oddite/deepdrivemd/src/deepdrivemd/aggregation/basic/aggregate.py -c /qfs/projects/oddite/leeh736/ddmd_runs/1k/agg_test.yaml &> agg_test_output.log
}

TRAINING () {

    task_id=task0000
    stage_name="machine_learning"
    dest_path=$EXPERIMENT_PATH/${stage_name}_runs/stage0000/$task_id
    stage_name="training"
    yaml_path=$DDMD_PATH/test/bba/${stage_name}_stage_test.yaml


    mkdir -p $EXPERIMENT_PATH/model_selection_runs/stage0000/$task_id/
    cp -p $DDMD_PATH/test/bba/stage0000_$task_id.json $EXPERIMENT_PATH/model_selection_runs/stage0000/$task_id/

    # module purge
    # module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
    # source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh
    source activate hermes_pytorch_ddmd

    mkdir -p $dest_path
    cd $dest_path
    # echo cd $dest_path

    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    # sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)

    # $LIBASAN:
    
    PYTHONPATH=$DDMD_PATH/:$MOLECULES_PATH mpirun -np 1 \
        -genv LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        -genv HERMES_CONF=$HERMES_CONF \
        -genv ADAPTER_MODE=SCRATCH \
        -genv HERMES_STOP_DAEMON=0 \
        -genv HERMES_CLIENT=1 \
        ~/.conda/envs/hermes_pytorch_ddmd/bin/python $DDMD_PATH/deepdrivemd/models/aae/train.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log 

}

INFERENCE () {

    task_id=task0000
    stage_name="inference"
    dest_path=$EXPERIMENT_PATH/${stage_name}_runs/stage0000/$task_id
    yaml_path=$DDMD_PATH/test/bba/${stage_name}_stage_test.yaml


    # module purge
    # module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
    # source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh
    source activate hermes_pytorch_ddmd

    mkdir -p $dest_path
    cd $dest_path
    # echo cd $dest_path

    mkdir -p $EXPERIMENT_PATH/agent_runs/stage0000/$task_id/


    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)

    PYTHONPATH=$DDMD_PATH/:$MOLECULES_PATH mpirun -n 1 \
        -genv LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
        -genv HERMES_CONF=$HERMES_CONF \
        -genv ADAPTER_MODE=SCRATCH \
        -genv HERMES_STOP_DAEMON=1 \
        -genv HERMES_CLIENT=1 \
        -genv OMP_NUM_THREADS=4 \
        ~/.conda/envs/hermes_pytorch_ddmd/bin/python $DDMD_PATH/deepdrivemd/agents/lof/lof.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log 
}
#

# Python environment on Bluesky
# module load python/miniconda3.7 gcc/9.1.0

START_HERMES_DAEMON (){
    for node in $NODE_NAMES
    do
        echo $node
        # export HERMES_CONF=${HERMES_CONF}
        srun -w $node -n1 -N1 mpirun -np 1 -genv HERMES_CONF=${HERMES_CONF} ${HERMES_INSTALL_DIR}/bin/hermes_daemon &
    done
}

STOP_HERMES_DAEMON(){
    for node in $NODE_NAMES
    do
        srun -w $node -n1 -N1 killall hermes_daemon
    done
}

# start hermes
hostname;date;

# STAGE 0: Start hermes_daemon
# mpirun -np $NODE_COUNT --map-by ppr:1:node --host $hostlist killall hermes_daemon
# mpirun -np $NODE_COUNT --map-by ppr:1:node --host $hostlist -x HERMES_CONF=${HERMES_CONF} ${HERMES_INSTALL_DIR}/bin/hermes_daemon &

set -x
mpirun -np $NODE_COUNT -ppn 1 -host $hostlist killall hermes_daemon
sleep 3
mpirun -np $NODE_COUNT -ppn 1 -host $hostlist -genv HERMES_CONF=${HERMES_CONF} ${HERMES_INSTALL_DIR}/bin/hermes_daemon &
sleep 3
ls -l /state/partition1/tang584/hermes_slabs
set +x

# ls -l /state/partition1/tang584/hermes_slabs

for iter in $(seq $ITER_COUNT)
do

    # STAGE 1: OpenMM
    start_time=$SECONDS
    (
    for node in $NODE_NAMES
    do
        while [ $MD_SLICE -gt 0 ] && [ $MD_START -lt $MD_RUNS ]
        do
            OPENMM $MD_START $node
            MD_START=$(($MD_START + 1))
            MD_SLICE=$(($MD_SLICE - 1))
        done
        MD_SLICE=$(($MD_RUNS/$NODE_COUNT))
    done

    wait)

    duration=$(($SECONDS - $start_time))
    echo "OpenMM done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
    ls $EXPERIMENT_PATH/molecular_dynamics_runs/*/* -hl

    # STAGE 2: Aggregate
    start_time=$SECONDS
    srun -N1 $( AGGREGATE )
    # wait
    duration=$(($SECONDS - $start_time))
    echo "Aggregate done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
    ls $EXPERIMENT_PATH/molecular_dynamics_runs/stage0000/task0000 -hl

    # STAGE 3: Training
    start_time=$SECONDS
    srun -N1 $( TRAINING )
    # wait
    duration=$(($SECONDS - $start_time))
    echo "Training done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
    ls $EXPERIMENT_PATH/machine_learning_runs/*/* -hl
    # $EXPERIMENT_PATH/model_selection_runs exist after training

    # STAGE 4: Inference
    start_time=$SECONDS
    srun $( INFERENCE )
    # wait
    duration=$(($SECONDS - $start_time))
    echo "Inference done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
    ls $EXPERIMENT_PATH/inference_runs/*/* -hl

done

hostname;date;
sacct -j $SLURM_JOB_ID -o jobid,submit,start,end,state
rm -rf $SCRIPT_DI/core.*
