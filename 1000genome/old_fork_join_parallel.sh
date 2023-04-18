#!/bin/bash  
#SBATCH -A oddite
#SBATCH --job-name="test_1k"
#SBATCH -N 15
#SBATCH -n 300
#SBATCH -x node32
#SBATCH --time=01:30:00
#SBATCH --output=R_%x.out
#SBATCH --error=R_%x.err

NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`
SCRIPT_DIR=/qfs/projects/oddite/lenny/1000genome-workflow/bin
CURRENT_DIR=/qfs/projects/oddite/lenny/hermes_scripts/1kgenome_sbatch

PROBLEM_SIZE=300 # the maximum number of tasks within a stage !!!need to modify as needed!!!
# the `SBATCH -N -n` needs to modify as well !!!
NUM_TASKS_PER_NODE=20 # (fixed) This is the max number of cores per node
NUM_NODES=$(((PROBLEM_SIZE+NUM_TASKS_PER_NODE-1)/NUM_TASKS_PER_NODE))
echo "PROBLEM SIZE: $PROBLEM_SIZE NUM_TASKS_PER_NODE: $NUM_TASKS_PER_NODE NUM_NODES: $NUM_NODES"

module purge
# module load python/3.7.0 gcc/11.2.0 # Lenny
module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh

set -x

NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`
list=()
while read -ra tmp; do
    list+=("${tmp[@]}")
done <<< "$NODE_NAMES"

START_INDIVIDUALS() {
    INCREMENT=1
    a=1
    b=2
    counter=0
    NNODES=$((NUM_NODES-1))
    chrk=1

    echo "nodelist: ${list[0]} ${list[1]}"

    for i in $(seq 0 $NNODES)
    do
        for j in $(seq 1 $NUM_TASKS_PER_NODE)
	do
	    echo "$i $j"
            if [ "$counter" -lt "$PROBLEM_SIZE" ] 
            then 
               echo "running node: ${list[$i]} t$i $a $b"
               # No need to change. This is the smallest input allowed.
               srun -w ${list[$i]} -n1 -N1 --exclusive $SCRIPT_DIR/individuals.py $CURRENT_DIR/ALL.chr${chrk}.250000.vcf $chrk $a $b 30 &
               if [ "$b" == 30 ]
               then
                   echo "a: $a b: $b chr: $chrk"
                   a=1
                   b=2
                   let chrk=chrk+1
               fi
               if [ "$b" == 30 ] && [ "$chrk" == 10 ]
               then
                   echo "All individuals tasks are submitted ..."
                   break 2
               fi
               a=$(($a + $INCREMENT))
               b=$(($b + $INCREMENT))
	       counter=$((counter++))       
            fi
	done
    done
    # sleep 3
    set +x
}

START_INDIVIDUALS_MERGE() {
    for i in $(seq 1 10) 
    do
	# 10 merge tasks in total
        srun -w ${list[$i]} -n1 -N1 --exclusive $SCRIPT_DIR/individuals_merge.py $i chr${i}n*.tar.gz &
    done
}

START_SIFTING() {
    for i in $(seq 1 10)
    do
        # 10 sifting tasks in total
        srun -w ${list[$i]} -n1 -N1 --exclusive $SCRIPT_DIR/sifting.py ALL.chr${i}.phase3_shapeit2_mvncall_integrated_v5.20130502.sites.annotation.vcf $i &
    done
}

START_MUTATION_OVERLAP() {
    FNAMES=("SAS EAS GBR AMR AFR EUR ALL")
    for i in $(seq 1 10)
    do
        for j in $FNAMES
	do
	    srun -w ${list[$i]} -n1 -N1 --exclusive $SCRIPT_DIR/mutation_overlap.py -c $i -pop $j &
	done
    done
}

START_FREQUENCY() {
    FNAMES=("SAS EAS GBR AMR AFR EUR ALL")
    for i in $(seq 1 10)
    do
	for j in $FNAMES
	do
	    #srun -w ${list[$i]} -n1 -N1 --exclusive $SCRIPT_DIR/frequency.py -c $i -pop $j &
	    echo $FNAMES
	done
    done
}

START_INDIVIDUALS
wait

# individuals_merge and sifting can run concurrently
START_INDIVIDUALS_MERGE

START_SIFTING
wait

# mutation_overlap and frequency can run concurrently
START_MUTATION_OVERLAP

START_FREQUENCY
wait
