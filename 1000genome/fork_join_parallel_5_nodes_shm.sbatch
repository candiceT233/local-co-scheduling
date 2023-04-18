#!/bin/bash
#SBATCH --job-name="5nodes_shm"
#SBATCH --partition=slurm
#SBATCH -A chess
#SBATCH -N 5
#SBATCH -n 100
#SBATCH --time=01:30:00
#SBATCH --output=R_%x.out
#SBATCH --error=R_%x.err

```
SBATCH -A oddite
SBATCH -x node32
SBATCH -x node24
```


NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`

SHARE="NFS" # PFS
LOCAL="SHM" #

if [ "$LOCAL" == "SHM" ]
then
    echo "Running on ramdisk"; export LOCAL_STORE=/dev/shm/$USER #shm
else
    echo "Running on SSD"; export LOCAL_STORE=/state/partition1/$USER
fi

if [ "$SHARE" == "NFS" ]
then
    echo "Running on NFS"
    # SCRIPT_DIR=/qfs/projects/oddite/lenny/1000genome-workflow/bin
    # CURRENT_DIR=/qfs/projects/oddite/lenny/hermes_scripts/1kgenome_sbatch #NFS
    SCRIPT_DIR=/qfs/projects/oddite/tang584/1000genome-workflow/bin
    CURRENT_DIR=/qfs/projects/oddite/tang584/1kgenome_sbatch #NFS
else
    echo "Running on PFS" # but this behaves like NFS
    SCRIPT_DIR=/files0/oddite/$USER/1000genome-workflow/bin
    CURRENT_DIR=/files0/oddite/$USER/1kgenome_sbatch #PFS
    mkdir -p $SCRIPT_DIR $CURRENT_DIR
    if ! [ -s "$SCRIPT_DIR" ]; then cp -r /files0/oddite/lenny/1000genome-workflow/bin/* $SCRIPT_DIR/; fi
    if ! [ -s "$CURRENT_DIR" ]; then cp -r /files0/oddite/lenny/hermes_scripts/1kgenome_sbatch/* $CURRENT_DIR/; fi
fi

# /files0/oddite/$USER/1kgenome_sbatch #SSD Burst Buffer

PROBLEM_SIZE=300 # the maximum number of tasks within a stage !!!need to modify as needed!!!
# the `SBATCH -N -n` needs to modify as well !!!
NUM_NODES=$SLURM_JOB_NUM_NODES
NUM_TASKS_PER_NODE=$(((PROBLEM_SIZE+NUM_TASKS_PER_NODE)/NUM_NODES)) # (fixed) This is the max number of cores per node
#NUM_NODES=$(((PROBLEM_SIZE+NUM_TASKS_PER_NODE-1)/NUM_TASKS_PER_NODE))
echo "PROBLEM SIZE: $PROBLEM_SIZE NUM_TASKS_PER_NODE: $NUM_TASKS_PER_NODE NUM_NODES: $NUM_NODES"

# module purge
# module load python/3.7.0 gcc/11.2.0

module purge
module load python/miniconda3.7 gcc/9.1.0
PYTHON_PATH=/share/apps/python/miniconda3.7/bin/python

NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`
list=()
while read -ra tmp; do
    list+=("${tmp[@]}")
done <<< "$NODE_NAMES"

host_list=$(echo "$NODE_NAMES" | tr '\n' ',')
echo "host_list: $host_list"
# readarray -t host_list <<< "$NODE_NAMES"

LOCAL_CLEANUP () {
    # for node in "${host_list[@]}"
    # do
    #     srun -n1 -N1 -w $node --exclusive rm -fr $LOCAL_STORE/*gz
    # done
    echo "Cleaning up local data at $LOCAL_STORE ..."
    srun -n5 -w $host_list --exclusive rm -fr $LOCAL_STORE/*gz
}

START_INDIVIDUALS() {
    # set -x
    # rm -fr $LOCAL_STORE/chr*tar.gz
    start_time_indiv=$SECONDS
    INCREMENT=1
    a=1
    b=2
    counter=0
    NNODES=$((NUM_NODES-1))
    chrk=1

    t_count=1

    echo "nodelist: ${list[0]} ${list[1]}"

    for i in $(seq 0 $NNODES)
    do
        for j in $(seq 1 29)
	do
	    echo "$i $j"
            if [ "$counter" -lt "$PROBLEM_SIZE" ]
            then

                echo "running node: ${list[$i]} t$i $a $b"
                let ii=i+1
                # No need to change. This is the smallest input allowed.
                srun -w ${list[$i]} -n1 -N1 --exclusive $PYTHON_PATH $SCRIPT_DIR/individuals_shm.py $CURRENT_DIR/ALL.chr${ii}.250000.vcf $ii $j $((j+1)) 30 &


                # if [ "$b" == 30 ]
                # then
                #     echo "a: $a b: $b chr: $chrk"
                #     a=0
                #     b=1
                # fi
                # if [ "$b" == 30 ] && [ "$ii" == 10 ]
                # then
                #     echo "All individuals tasks are submitted ..."
                #     break 2
                # fi
                # a=$(($a + $INCREMENT))
                # b=$(($b + $INCREMENT))

                counter=$(($counter++))
                t_count=$(($t_count++))

                echo "counter: $counter"
                echo "t_count: $t_count"
                if [[ $t_count == 20 ]]
                then
                    echo "finished launching $t_count tasks, now wait"
                    t_count=1
                    wait
                fi

            fi
	done
    done
    # sleep 3
    set +x

    duration_indiv=$(($SECONDS - $start_time_indiv))
    echo "Individuals launched ... $(($duration_indiv / 3600)) seconds and $(($duration_indiv % 3600)) milliseconds elapsed."
}

START_INDIVIDUALS_MERGE() {
    NNODES=$((NUM_NODES-1))
    start_time_merge=$SECONDS
    for i in $(seq 0 $NNODES)
    do
	let ii=i+1
	# 10 merge tasks in total
        srun -w ${list[$i]} -n1 -N1 --exclusive $PYTHON_PATH $SCRIPT_DIR/individuals_merge_shm.py $ii $LOCAL_STORE/chr${ii}n-1-2.tar.gz $LOCAL_STORE/chr${ii}n-2-3.tar.gz $LOCAL_STORE/chr${ii}n-3-4.tar.gz $LOCAL_STORE/chr${ii}n-4-5.tar.gz $LOCAL_STORE/chr${ii}n-5-6.tar.gz $LOCAL_STORE/chr${ii}n-6-7.tar.gz $LOCAL_STORE/chr${ii}n-7-8.tar.gz $LOCAL_STORE/chr${ii}n-8-9.tar.gz $LOCAL_STORE/chr${ii}n-9-10.tar.gz $LOCAL_STORE/chr${ii}n-10-11.tar.gz $LOCAL_STORE/chr${ii}n-11-12.tar.gz $LOCAL_STORE/chr${ii}n-12-13.tar.gz $LOCAL_STORE/chr${ii}n-13-14.tar.gz $LOCAL_STORE/chr${ii}n-14-15.tar.gz $LOCAL_STORE/chr${ii}n-15-16.tar.gz $LOCAL_STORE/chr${ii}n-16-17.tar.gz $LOCAL_STORE/chr${ii}n-17-18.tar.gz $LOCAL_STORE/chr${ii}n-18-19.tar.gz $LOCAL_STORE/chr${ii}n-19-20.tar.gz $LOCAL_STORE/chr${ii}n-20-21.tar.gz $LOCAL_STORE/chr${ii}n-21-22.tar.gz $LOCAL_STORE/chr${ii}n-22-23.tar.gz $LOCAL_STORE/chr${ii}n-23-24.tar.gz $LOCAL_STORE/chr${ii}n-24-25.tar.gz $LOCAL_STORE/chr${ii}n-25-26.tar.gz $LOCAL_STORE/chr${ii}n-26-27.tar.gz $LOCAL_STORE/chr${ii}n-27-28.tar.gz $LOCAL_STORE/chr${ii}n-28-29.tar.gz $LOCAL_STORE/chr${ii}n-29-30.tar.gz &
    done

    duration_merge=$(($SECONDS - $start_time_merge))
    echo "Individuals merge launched ... $(($duration_merge / 3600)) seconds and $(($duration_merge % 3600)) milliseconds elapsed."
}

START_SIFTING() {
    NNODES=$((NUM_NODES-1))
    start_time_sift=$SECONDS
    for i in $(seq 0 $NNODES)
    do
        # 10 sifting tasks in total
	let ii=i+1
        srun -w ${list[$i]} -n1 -N1 --exclusive $PYTHON_PATH $SCRIPT_DIR/sifting.py ALL.chr${ii}.phase3_shapeit2_mvncall_integrated_v5.20130502.sites.annotation.vcf $ii &
    done

    duration_sift=$(($SECONDS - $start_time_sift))
    echo "Sifting launched ... $(($duration_sift / 3600)) seconds and $(($duration_sift % 3600)) milliseconds elapsed."
}

START_MUTATION_OVERLAP() {
    NNODES=$((NUM_NODES-1))
    start_time_mutat=$SECONDS
    FNAMES=("SAS EAS GBR AMR AFR EUR ALL")
    for i in $(seq 0 $NNODES)
    do
        for j in $FNAMES
	do
	    let ii=i+1
	    srun -w ${list[$i]} -n1 -N1 --exclusive $PYTHON_PATH $SCRIPT_DIR/mutation_overlap_shm.py -c $ii -pop $j &
	done
    done

    duration_mutat=$(($SECONDS - $start_time_mutat))
    echo "Mutation overlap launched ... $(($duration_mutat / 3600)) seconds and $(($duration_mutat % 3600)) milliseconds elapsed."
}

START_FREQUENCY() {
    NNODES=$((NUM_NODES-1))
    start_time_freq=$SECONDS
    FNAMES=("SAS EAS GBR AMR AFR EUR ALL")
    for i in $(seq 0 $NNODES)
    do
	for j in $FNAMES
	do
	    let ii=i+1
	    srun -w ${list[$i]} -n1 -N1 --exclusive $PYTHON_PATH $SCRIPT_DIR/frequency_shm.py -c $ii -pop $j &
	done
    done

    duration_freq=$(($SECONDS - $start_time_freq))
    echo "Frequency launched ... $(($duration_freq / 3600)) seconds and $(($duration_freq % 3600)) milliseconds elapsed."
}


hostname;date;
echo "Making directory at $LOCAL_STORE ..."
srun -n5 -w $host_list --exclusive mkdir -p $LOCAL_STORE


LOCAL_CLEANUP

total_start_time=$(($(date +%s%N)/1000000))

cd $CURRENT_DIR
start_time=$(($(date +%s%N)/1000000))
START_INDIVIDUALS
wait
echo "individuals (msec) : $(($(date +%s%N)/1000000 - $start_time))"

start_time=$(($(date +%s%N)/1000000))
START_INDIVIDUALS_MERGE
START_SIFTING
wait

echo "individuals_merge+sifting (msec) : $(($(date +%s%N)/1000000 - $start_time))"

# start_time=$(($(date +%s%N)/1000000))
# START_MUTATION_OVERLAP
# START_FREQUENCY
# wait
# echo "mutation+frequency (msec) : $(($(date +%s%N)/1000000 - $start_time))"

total_duration=$(( $(date +%s%N)/1000000 - $total_start_time))
echo "All done... $total_duration milliseconds elapsed."

LOCAL_CLEANUP

hostname;date;
sacct -j $SLURM_JOB_ID -o jobid,submit,start,end,state
