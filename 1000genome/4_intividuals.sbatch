#!/bin/bash  
#SBATCH -A oddite
#SBATCH --job-name="4genome_250000_mem6G"
#SBATCH -N 4
#SBATCH -n 4
#SBATCH --time=01:30:00
#SBATCH --output=R_%x.out                                        
#SBATCH --error=R_%x.err



module purge
module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 
#openmpi/4.1.3
source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh

# ulimit -c unlimited
ulimit -v 4G
# source /qfs/projects/oddite/hermes_stage/load_hermes_dep.sh
# . ~/spack/share/spack/setup-env.sh
# source /qfs/people/tang584/hermes_stage/hermes/load_hermes_dep.sh

SIZE=250000
NODE_COUNT=$SLURM_JOB_NUM_NODES

NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`
SCRIPT_DIR=/qfs/projects/oddite/lenny/1000genome-workflow/bin


# HERMES_DEFAULT_CONF=/qfs/projects/oddite/lenny/hermes_scripts/1000_hermes_default.yaml
# HERMES_CONF=/qfs/projects/oddite/lenny/hermes_scripts/1000_hermes.yaml
# HERMES_SCRIPT=/qfs/projects/oddite/lenny/hermes_scripts
HERMES_SCRIPT=$HOME/scripts/local-co-scheduling/1000genome


# get nodelist to hermes config file
if [ "$NODE_COUNT" = "1" ]; then
    sed "s/\$HOST_BASE_NAME/\"localhost\"/" $HERMES_DEFAULT_CONF  > $HERMES_CONF
    sed -i "s/\$HOST_NUMBER_RANGE/ /" $HERMES_CONF
else
    sed "s/\$HOST_BASE_NAME/\"node\"/" $HERMES_DEFAULT_CONF  > $HERMES_CONF
    rpc_host_number_range=$(echo "$SLURM_JOB_NODELIST" | grep -Po '[\[].*[\]]')
    sed -i "s/\$HOST_NUMBER_RANGE/${rpc_host_number_range}/" $HERMES_CONF
fi

# echo "SLURM_STEP_NUM_TASKS = $SLURM_STEP_NUM_TASKS"
echo "NODE_NAMES = $NODE_NAMES"
echo "SLURM_JOB_NODELIST = $SLURM_JOB_NODELIST"
hostlist=$(echo -e "$NODE_NAMES" | xargs | sed -e 's/ /,/g')
echo "hostlist = $hostlist"



START_INDIVIDUALS () {
    list=()
    while read -ra tmp; do
        list+=("${tmp[@]}")
    done <<< "$NODE_NAMES"

    if [ $SIZE -eq 250000 ]
    then
        INCREMENT=1000
        a=1
        b=1001
    else
        INCREMENT=1
        a=0
        b=1
    fi

    set -x

    for i in {0..3}
    do
        a=$(($a + $INCREMENT))
        b=$(($b + $INCREMENT))
        echo "running node: ${list[$i]} t$i $a $b"
        $SCRIPT_DIR/individuals.py $HERMES_SCRIPT/ALL.chr1.250000.vcf 1 $a $b $SIZE &
    done
    # sleep 3
    set +x
}


# mpirun -np 2 --map-by ppr:1:node --host $hostlist

hostname;date;
set -x
rm -rf $HERMES_SCRIPT/chr1n-*

start_time=$SECONDS
START_INDIVIDUALS
wait
duration=$(($SECONDS - $start_time))
echo "INDIVIDUALS done... $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

ls -lh $HERMES_SCRIPT | grep "chr1n-"

set +x

hostname;date;
sacct -j $SLURM_JOB_ID -o jobid,submit,start,end,state
rm -rf core.*
