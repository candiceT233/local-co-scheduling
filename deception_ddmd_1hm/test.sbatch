#!/bin/bash
#SBATCH --job-name=mochi-test
#SBATCH --partition=a100
#SBATCH --account=chess
#SBATCH --time=00:30:00
#SBATCH -N 2
#SBATCH -n 2
#SBATCH --output=./R_%x.out                                        
#SBATCH --error=./R_%x.err
#SBATCH --mem=0

SKIP_OPENMM=false
SHORTENED_PIPELINE=true
S1_HM=true
MD_RUNS=12
ITER_COUNT=1 # TBD
SIM_LENGTH=0.1
SIZE=$(echo "$SIM_LENGTH * 1000" | bc)
SIZE=${SIZE%.*}
TRIAL=0
ADAPTER_MODE="WORKFLOW"

TEST_OUT_PATH=hermes_test_${SIZE}ps_i${ITER_COUNT}_${TRIAL}

# EXPERIMENT_PATH=/rcfs/projects/chess/$USER/ddmd_runs/$TEST_OUT_PATH #PFS
EXPERIMENT_PATH=/qfs/projects/oddite/tang584/ddmd_runs/$TEST_OUT_PATH #NFS
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


# OPENMM_PYTHON=~/.conda/envs/hm_ddmd_openmm_deception/bin/python
# PYTORCH_PYTHON=~/.conda/envs/hm_ddmd_pytorch_deception/bin/python

# module purge
# module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
# source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh

# load environment variables for Hermes
ulimit -c unlimited
# . $HOME/zen2_dec/dec_spack/share/spack/setup-env.sh
source $HOME/scripts/local-co-scheduling/load_hermes_deps.sh
# source $HOME/scripts/local-co-scheduling/network_load.sh
source $HOME/scripts/local-co-scheduling/env_var.sh

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
    sed -i "s/\$INTERCEPT_PATHS/ /" $HERMES_CONF
}


HERMES_DIS_CONFIG () {

    echo "SLURM_JOB_NODELIST = $(echo $SLURM_JOB_NODELIST|scontrol show hostnames)"
    NODE_NAMES=$(echo $SLURM_JOB_NODELIST|scontrol show hostnames)

    # prefix="dlt0"
    sed "s/\$HOST_BASE_NAME/\"dlt0\"/" $HERMES_DEFAULT_CONF  > $HERMES_CONF
    mapfile -t node_range < <(echo "$NODE_NAMES" | sed 's/dlt0//g')
    rpc_host_number_range="[$(printf "%s," "${node_range[@]}" | sed 's/,$//')]"
    sed -i "s/\$HOST_NUMBER_RANGE/${rpc_host_number_range}/" $HERMES_CONF

    echo "node_range=${node_range[@]}"
    echo "rpc_host_number_range=$rpc_host_number_range"

    # echo "$NODE_NAMES" | sed 's/$/.ibnet/' > $SCRIPT_DIR/host_ip
    # cat $SCRIPT_DIR/host_ip

    # INTERCEPT_PATHS=$(sed "s/\$TEST_OUT_PATH/${TEST_OUT_PATH}/g" i${ITER_COUNT}_sim_files.txt)
    # echo "$INTERCEPT_PATHS" >> $HERMES_CONF

    echo "]" >> $HERMES_CONF

}

START_HERMES_DAEMON () {
    # --mca shmem_mmap_priority 80 \ \
    # -mca mca_verbose stdout 
    # -x UCX_NET_DEVICES=mlx5_0:1 \
    # -mca btl self -mca pml ucx \

    echo "Starting hermes_daemon..."
    set -x
    # export LD_PRELOAD=/lib64/libucs.so:$LD_PRELOAD
    # export LD_LIBRARY_PATH=/lib64/ucx:$LD_LIBRARY_PATH
    # -x LD_PRELOAD=/usr/lib64/libucs.so$LD_PRELOAD \
    # -x UCX_NET_DEVICES=mlx5_0:1 \
    mpirun --host $hostlist --npernode 1 \
        -x HERMES_CONF=$HERMES_CONF $HERMES_INSTALL_DIR/bin/hermes_daemon &> ${FUNCNAME[0]}.log &

    # srun -n$NODE_COUNT -w $hostlist --mpi=pmi2 \
    #     -x HERMES_CONF=$HERMES_CONF $HERMES_INSTALL_DIR/bin/hermes_daemon &> ${FUNCNAME[0]}.log &

    sleep 5
    # echo ls -l $DEV1_DIR/hermes_slabs
    ls -l $DEV1_DIR/hermes_slabs
    set +x
}

TEST_MARGO (){
    for node in $NODE_NAMES
    do
        srun -w $node which ucx_info
        srun -w $node ucx_info -d
        srun -w $node which margo-info
        srun -w $node margo-info
    done
}


hostname;date;
set -x
TEST_MARGO

# srun -n$NODE_COUNT -w $hostlist killall hermes_daemon
# echo "Hermes Config : ADAPTER_MODE=$ADAPTER_MODE HERMES_PAGE_SIZE=$HERMES_PAGE_SIZE"

# HERMES_DIS_CONFIG
# START_HERMES_DAEMON

# STOP_DAEMON
# mpirun --host $hostlist --pernode killall hermes_daemon
# ls $EXPERIMENT_PATH/*/*/* -hl

hostname;date;
sacct -j $SLURM_JOB_ID -o jobid,submit,start,end,state
# rm -rf $SCRIPT_DIR/core.*

# --output=R_%x.%j.out --exclude=a100[06]
# --nodelist=a100-[03-06] --exclude=a100-[01-02]