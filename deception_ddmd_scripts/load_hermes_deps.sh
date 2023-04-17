#!/bin/bash

# spack load --only dependencies hermes
# spack unload mpich
# module purge
# module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
# source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh

module load openmpi/4.1.3

. $HOME/zen2_dec/dec_spack/share/spack/setup-env.sh

# spack load --only dependencies hermes


# set -x
MPI_PATH="`which mpicc |sed 's/.\{10\}$//'`"
MPI_BIN="$MPI_PATH/bin"
MPI_LIB="$MPI_PATH/lib"
MPI_INCLUDE="$MPI_PATH/include"
[[ ":$PATH:" != *":${MPI_BIN}:"* ]] && PATH="${MPI_BIN}:${PATH}"
[[ ":$LD_LIBRARY_PATH:" != *":${MPI_LIB}:"* ]] && LD_LIBRARY_PATH="${MPI_LIB}:${LD_LIBRARY_PATH}"
[[ ":$C_INCLUDE_PATH:" != *":${MPI_INCLUDE}:"* ]] && C_INCLUDE_PATH="${MPI_INCLUDE}:${C_INCLUDE_PATH}"


# MARGO_PATH="`which margo-info |sed 's/.\{15\}$//'`"
# MARGO_BIN="$MARGO_PATH/bin"
# MARGO_LIB="$MARGO_PATH/lib"
# MARGO_INCLUDE="$MARGO_PATH/include"
# [[ ":$PATH:" != *":${MARGO_BIN}:"* ]] && PATH="${MARGO_BIN}:${PATH}"
# [[ ":$LD_LIBRARY_PATH:" != *":${MARGO_LIB}:"* ]] && LD_LIBRARY_PATH="${MARGO_LIB}:${LD_LIBRARY_PATH}"
# [[ ":$C_INCLUDE_PATH:" != *":${MARGO_INCLUDE}:"* ]] && C_INCLUDE_PATH="${MARGO_INCLUDE}:${C_INCLUDE_PATH}"

# FABRIC_PATH="`which fi_info |sed 's/.\{12\}$//'`"
# FABRIC_BIN="$FABRIC_PATH/bin"
# FABRIC_LIB="$FABRIC_PATH/lib"
# FABRIC_INCLUDE="$FABRIC_PATH/include"
# [[ ":$PATH:" != *":${FABRIC_BIN}:"* ]] && PATH="${FABRIC_BIN}:${PATH}"
# [[ ":$LD_LIBRARY_PATH:" != *":${FABRIC_LIB}:"* ]] && LD_LIBRARY_PATH="${FABRIC_LIB}:${LD_LIBRARY_PATH}"
# [[ ":$C_INCLUDE_PATH:" != *":${FABRIC_INCLUDE}:"* ]] && C_INCLUDE_PATH="${FABRIC_INCLUDE}:${C_INCLUDE_PATH}"


MERCURY_PATH="/people/tang584/install/mercury"
MERCURY_LIB="$MERCURY_PATH/lib"
MERCURY_INCLUDE="$MERCURY_PATH/include"
[[ ":$LD_LIBRARY_PATH:" != *":${MERCURY_LIB}:"* ]] && LD_LIBRARY_PATH="${MERCURY_LIB}:${LD_LIBRARY_PATH}"
[[ ":$LD_RUN_PATH:" != *":${MERCURY_LIB}:"* ]] && LD_RUN_PATH="${MERCURY_LIB}:${LD_RUN_PATH}"
[[ ":$C_INCLUDE_PATH:" != *":${MERCURY_INCLUDE}:"* ]] && C_INCLUDE_PATH="${MERCURY_INCLUDE}:${C_INCLUDE_PATH}"


ARGOBOTS_PATH="/people/tang584/install/argobots"
ARGOBOTS_LIB="$ARGOBOTS_PATH/lib"
ARGOBOTS_INCLUDE="$ARGOBOTS_PATH/include"
[[ ":$LD_LIBRARY_PATH:" != *":${ARGOBOTS_LIB}:"* ]] && LD_LIBRARY_PATH="${ARGOBOTS_LIB}:${LD_LIBRARY_PATH}"
[[ ":$LD_RUN_PATH:" != *":${ARGOBOTS_LIB}:"* ]] && LD_RUN_PATH="${ARGOBOTS_LIB}:${LD_RUN_PATH}"
[[ ":$C_INCLUDE_PATH:" != *":${ARGOBOTS_INCLUDE}:"* ]] && C_INCLUDE_PATH="${ARGOBOTS_INCLUDE}:${C_INCLUDE_PATH}"

# spack load json-c
# JSONC_PATH="/qfs/people/tang584/zen2_dec/dec_spack/opt/spack/linux-centos7-zen2/gcc-9.1.0/json-c-0.16-t4fcaprpskmngtvy6sa5bam7bz5usthk"
JSONC_PATH="/qfs/people/tang584/install/json-c"
JSONC_LIB=$JSONC_PATH/lib64
JSONC_INCLUDE=$JSONC_PATH/include
[[ ":$LD_LIBRARY_PATH:" != *":${JSONC_LIB}:"* ]] && LD_LIBRARY_PATH="${JSONC_LIB}:${LD_LIBRARY_PATH}"
[[ ":$LD_RUN_PATH:" != *":${JSONC_LIB}:"* ]] && LD_RUN_PATH="${JSONC_LIB}:${LD_RUN_PATH}"
[[ ":$C_INCLUDE_PATH:" != *":${JSONC_INCLUDE}:"* ]] && C_INCLUDE_PATH="${JSONC_INCLUDE}:${C_INCLUDE_PATH}"


spack load mochi-thallium@0.8.3 catch2@3.0.1 glpk glog yaml-cpp

# HERMES_PATH="/qfs/people/tang584/install/dec_hermes"
# HERMES_BIN="$HERMES_PATH/bin"
# HERMES_LIB="$HERMES_PATH/lib"
# HERMES_INCLUDE="$HERMES_PATH/include"
# [[ ":$PATH:" != *":${HERMES_BIN}:"* ]] && PATH="${HERMES_BIN}:${PATH}"
# [[ ":$LD_LIBRARY_PATH:" != *":${HERMES_LIB}:"* ]] && LD_LIBRARY_PATH="${HERMES_LIB}:${LD_LIBRARY_PATH}"
# [[ ":$C_INCLUDE_PATH:" != *":${HERMES_INCLUDE}:"* ]] && C_INCLUDE_PATH="${HERMES_INCLUDE}:${C_INCLUDE_PATH}"


#spack load mochi-thallium@0.10.0 catch2@3.0.1 glpk glog yaml-cpp mpich #automake
# spack load boost mochi-thallium@0.8.3 catch2@3.0.1 glpk glog yaml-cpp mpich 

# spack load hermes
# spack load hdf5
# spack load mpich
#spack load libbsd
    
