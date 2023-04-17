#!/bin/bash  
#SBATCH -A oddite
#SBATCH --job-name="10nodes_shm"
#SBATCH -N 3
#SBATCH -n 3
#SBATCH --time=01:30:00
#SBATCH --output=R_%x.out
#SBATCH --error=R_%x.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=lenny.guo@pnnl.gov

NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`

SHARE="NFS" # PFS
LOCAL="SSD" # 

if [ "$LOCAL" == "SHM" ]
then
    echo "Running on ramdisk"; LOCAL_STORE=/dev/shm #shm
else
    echo "Running on SSD"; LOCAL_STORE=/state/partition1/$USER
fi


NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`
list=()
while read -ra tmp; do
    list+=("${tmp[@]}")
done <<< "$NODE_NAMES"

LOCAL_CLEANUP () {
    for node in $NODE_NAMES
    do 
        srun -w $node -n1 -N1 --exclusive rm -fr $LOCAL_STORE/*
    done
}


LOCAL_CLEANUP
