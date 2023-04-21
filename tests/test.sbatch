#!/bin/bash  
#SBATCH -A oddite
#SBATCH -N 2
#SBATCH -n 2
#SBATCH --nodelist=node[42,43]
#SBATCH --time=00:30:00
#SBATCH --job-name="hm_co"
#SBATCH --output=TEST_%x.out                                        
#SBATCH --error=TEST_%x.err


NODE_NAMES=`echo $SLURM_JOB_NODELIST|scontrol show hostnames`

echo "NODE_NAMES = $NODE_NAMES"
echo "SLURM_JOB_NODELIST = $SLURM_JOB_NODELIST"
# list=$(scontrol show hostname $SLURM_NODELIST)
hostlist=$(echo -e "$NODE_NAMES" | xargs | sed -e 's/ /,/g')
echo "hostlist = $hostlist"

HERMES_CONF=/qfs/people/tang584/scripts/local-co-scheduling/hermes.yaml
HERMES_INSTALL_DIR=/qfs/people/tang584/install/hermes
# hostname;date;

mpirun -np 2 --map-by ppr:1:node --host $hostlist date
mpirun -np 2 --map-by ppr:1:node --host $hostlist killall hermes_daemon
# mpirun -np 2 --map-by ppr:1:node --host $hostlist sleep 3

mpirun -np 2 --map-by ppr:1:node --host $hostlist -x HERMES_CONF=${HERMES_CONF} ${HERMES_INSTALL_DIR}/bin/hermes_daemon &
mpirun -np 2 --map-by ppr:1:node --host $hostlist sleep 3

mpirun -np 2 --map-by ppr:1:node --host $hostlist killall hermes_daemon