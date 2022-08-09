#!/bin/bash  
#SBATCH -A oddite
#SBATCH --nodelist=node42
#SBATCH --nodes=1                                                                     
#SBATCH --ntasks-per-node=12
#SBATCH --time=00:10:00
#SBATCH --job-name="hm_sim-20-80-80-R"
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

rm -rf molecular_dynamics_runs

conda activate hermes_ddmd

HDF5_DRIVER=hermes \
    HDF5_PLUGIN_PATH=${HERMES_BUILD_DIR}/lib/hermes_vfd \
    HDF5_DRIVER_CONFIG="true 65536" HERMES_CONF=${HERMES_CONF} \
    LD_PRELOAD=${HERMES_BUILD_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
    time python ${SCRIPT_DIR}/sim_emulator.py --residue 100 -n 6 -a 1000 -f 1000

ls ~/molecular_dynamics_runs/*/* -hl