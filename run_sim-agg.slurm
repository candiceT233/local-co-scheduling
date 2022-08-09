#!/bin/bash  
#SBATCH -A oddite
#SBATCH --nodelist=node43
#SBATCH --nodes=1                                                                     
#SBATCH --ntasks-per-node=12
#SBATCH --time=00:10:00
#SBATCH --job-name="hm_co"
#SBATCH --output=R_%x.%j.out                                        
#SBATCH --error=R_%x_%j.err

module purge
module load python/miniconda3.7 gcc/9.1.0 cmake/3.21.4 git/2.31.1    #openmpi/4.1.3 # openmpi/4.1.3   cmake/3.21.4  
source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh
ulimit -c unlimited
. /people/tang584/spack/share/spack/setup-env.sh

source /people/tang584/load_hermes_dep.sh

source /people/tang584/scripts/co-scheduling/env_var.sh

set -x

hostname;date;

# start hermes
mkdir -p /state/partition1/hermes_slabs
mkdir -p /files0/oddite/hermes_slabs
mkdir -p /files0/oddite/hermes_swap
#rm -rf /state/partition1/hermes_slabs/*

rm -rf aggregate.h5

conda activate hermes_ddmd

# Start a daemon
HERMES_CONF=${HERMES_CONF} \
${HERMES_INSTALL_DIR}/bin/hermes_daemon &
sleep 3


LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/libhermes_posix.so \
HERMES_CONF=${HERMES_CONF} \
HERMES_STOP_DAEMON=0 \
ADAPTER_MODE=DEFAULT \
python /people/tang584/scripts/co-scheduling/sim_emulator.py --residue 100 -n 1 -a 100 -f 1000


ls molecular_dynamics_runs/*/* -hl # check file size for correctness

LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/libhermes_posix.so \
HERMES_CONF=${HERMES_CONF} \
HERMES_STOP_DAEMON=1 \
ADAPTER_MODE=DEFAULT \
python /people/tang584/scripts/co-scheduling/aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5

ls -lrtah | grep "aggregate.h5" # check file size for correctness
