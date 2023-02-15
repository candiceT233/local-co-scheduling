#!/bin/bash
#SBATCH --job-name=deepdrivemd
#SBATCH --account=oddite
#SBATCH --time=00:30:00
#SBATCH -N 2
#SBATCH -n 12
#SBATCH --output=R_%x.out                                        
#SBATCH --error=R_%x.err

# --output=R_%x.%j.out

MD_RUNS=12
ITER_COUNT=1 # TBD
SIM_LENGTH=0.1 #1.6

NODE_COUNT=2
GPU_PER_NODE=6
MD_START=0
MD_SLICE=$(($MD_RUNS/$NODE_COUNT))
NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`

EXPERIMENT_PATH=/qfs/projects/oddite/tang584/ddmd_runs/test_1600ps
DDMD_PATH=/people/tang584/scripts/deepdrivemd
MOLECULES_PATH=/qfs/projects/oddite/tang584/git/molecules

# OPENMM_PYTHON=~/.conda/envs/hermes_openmm_ddmd/bin/python
# PYTORCH_PYTHON=~/.conda/envs/hermes_pytorch_ddmd/bin/python

set -x

# rm -rf $EXPERIMENT_PATH/*
# ls $EXPERIMENT_PATH/* -hl


module purge
module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh
# conda activate hermes_ddmd #/files0/oddite/conda/ddmd/
# source /qfs/people/tang584/scripts/local-co-scheduling/venv_ddmd/bin/activate

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


    module purge
    module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
    source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh
    source activate hermes_openmm_ddmd

    mkdir -p $dest_path
    cd $dest_path
    echo cd $dest_path

    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" -e "s/\$DDMD_PATH/${DDMD_PATH//\//\\/}/" -e "s/\$GPU_IDX/${gpu_idx}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)

    PYTHONPATH=$DDMD_PATH:$MOLECULES_PATH srun -w $node_id -n1 -N1 --exclusive ~/.conda/envs/hermes_openmm_ddmd/bin/python $DDMD_PATH/deepdrivemd/sim/openmm/run_openmm.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log &
    #PYTHONPATH=~/git/molecules/ srun -w $node_id -N1 python /people/leeh736/git/DeepDriveMD-pipeline/deepdrivemd/sim/openmm/run_openmm.py -c $yaml_path &>> $task_id.log &
    #srun -n1 env LD_PRELOAD=~/git/tazer_forked/build.h5/src/client/libclient.so PYTHONPATH=~/git/molecules/ python /people/leeh736/git/DeepDriveMD-pipeline/deepdrivemd/sim/openmm/run_openmm.py -c /qfs/projects/oddite/leeh736/ddmd_runs/test/md_direct.yaml &> $task_id.log &
}

AGGREGATE () {

    task_id=task0000
    stage_name="aggregate"
    dest_path=$EXPERIMENT_PATH/molecular_dynamics_runs/stage0000/$task_id
    yaml_path=$DDMD_PATH/test/bba/${stage_name}_stage_test.yaml


    module purge
    module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
    source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh
    source activate hermes_openmm_ddmd


    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)

    { time PYTHONPATH=$DDMD_PATH/ ~/.conda/envs/hermes_openmm_ddmd/bin/python $DDMD_PATH/deepdrivemd/aggregation/basic/aggregate.py -c $yaml_path ; } &> ${task_id}_${FUNCNAME[0]}.log 

    #env LD_PRELOAD=/qfs/people/leeh736/git/tazer_forked/build.h5.pread64.bluesky/src/client/libclient.so PYTHONPATH=~/git/deepdrivemd/ python /files0/oddite/deepdrivemd/src/deepdrivemd/aggregation/basic/aggregate.py -c /qfs/projects/oddite/leeh736/ddmd_runs/1k/agg_test.yaml &> agg_test_output.log
}

TRAINING () {

    task_id=task0000
    stage_name="machine_learning"
    dest_path=$EXPERIMENT_PATH/${stage_name}_runs/stage0000/$task_id
    stage_name="training"
    yaml_path=$DDMD_PATH/test/bba/${stage_name}_stage_test.yaml


    mkdir -p $EXPERIMENT_PATH/model_selection_runs/stage0000/task0000/
    cp -p $DDMD_PATH/test/bba/stage0000_task0000.json $EXPERIMENT_PATH/model_selection_runs/stage0000/task0000/

    module purge
    module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
    source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh
    source activate hermes_pytorch_ddmd

    mkdir -p $dest_path
    cd $dest_path
    echo cd $dest_path

    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)

   PYTHONPATH=$DDMD_PATH/:$MOLECULES_PATH ~/.conda/envs/hermes_pytorch_ddmd/bin/python $DDMD_PATH/deepdrivemd/models/aae/train.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log 

}

INFERENCE () {

    task_id=task0000
    stage_name="inference"
    dest_path=$EXPERIMENT_PATH/${stage_name}_runs/stage0000/$task_id
    yaml_path=$DDMD_PATH/test/bba/${stage_name}_stage_test.yaml


    module purge
    module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
    source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh
    source activate hermes_pytorch_ddmd

    mkdir -p $dest_path
    cd $dest_path
    echo cd $dest_path

    mkdir -p $EXPERIMENT_PATH/agent_runs/stage0000/task0000/


    sed -e "s/\$SIM_LENGTH/${SIM_LENGTH}/" -e "s/\$OUTPUT_PATH/${dest_path//\//\\/}/" -e "s/\$EXPERIMENT_PATH/${EXPERIMENT_PATH//\//\\/}/" $yaml_path  > $dest_path/$(basename $yaml_path)
    yaml_path=$dest_path/$(basename $yaml_path)


   OMP_NUM_THREADS=4 PYTHONPATH=$DDMD_PATH/:$MOLECULES_PATH ~/.conda/envs/hermes_pytorch_ddmd/bin/python $DDMD_PATH/deepdrivemd/agents/lof/lof.py -c $yaml_path &> ${task_id}_${FUNCNAME[0]}.log 

}
#

# Python environment on Bluesky
module load python/miniconda3.7 gcc/9.1.0
source activate openmm

for iter in $(seq $ITER_COUNT)
do

    # # STAGE 1: OpenMM
    # for node in $NODE_NAMES
    # do
    #     while [ $MD_SLICE -gt 0 ] && [ $MD_START -lt $MD_RUNS ]
    #     do
    #         echo $node
    #         OPENMM $MD_START $node
    #         MD_START=$(($MD_START + 1))
    #         MD_SLICE=$(($MD_SLICE - 1))
    #     done
    #     MD_SLICE=$(($MD_RUNS/$NODE_COUNT))
    # done

    # wait

    echo "OpenMM done..."
    ls $EXPERIMENT_PATH/molecular_dynamics_runs/*/* -hl

    # # STAGE 2: Aggregate
    # srun -N1 $( AGGREGATE )
    # wait

    echo "Aggregate done..."
    ls $EXPERIMENT_PATH/molecular_dynamics_runs/stage0000/task0000 -hl

    # stage0000/$task_id

    # # STAGE 3: Training
    # srun -N1 $( TRAINING )
    # wait

    echo "Training done..."
    ls $EXPERIMENT_PATH/machine_learning_runs/*/* -hl

    # STAGE 4: Inference

    srun $( INFERENCE )
    wait

    echo "Inference done..."
    ls $EXPERIMENT_PATH/inference_runs/*/* -hl

done

sacct -j $SLURM_JOB_ID -o jobid,submit,start,end,state
