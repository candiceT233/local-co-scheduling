#!/bin/bash

# module load openmpi/4.1.3

. $HOME/zen2_dec/dec_spack/share/spack/setup-env.sh
spack load boost

# BOOST_PATH="/people/tang584/install/boost"
# BOOST_LIB="$BOOST_PATH/lib"
# BOOST_INCLUDE="$BOOST_PATH/include"
# [[ ":$LD_LIBRARY_PATH:" != *":${BOOST_LIB}:"* ]] && LD_LIBRARY_PATH="${BOOST_LIB}:${LD_LIBRARY_PATH}"
# [[ ":$LD_RUN_PATH:" != *":${BOOST_LIB}:"* ]] && LD_RUN_PATH="${BOOST_LIB}:${LD_RUN_PATH}"
# [[ ":$C_INCLUDE_PATH:" != *":${BOOST_INCLUDE}:"* ]] && C_INCLUDE_PATH="${BOOST_INCLUDE}:${C_INCLUDE_PATH}"
# # BOOST_PACKAGE=$BOOST_LIB/pkgconfig
# # [[ ":$PKG_CONFIG_PATH:" != *":${BOOST_PACKAGE}:"* ]] && PKG_CONFIG_PATH="${BOOST_PACKAGE}:${PKG_CONFIG_PATH}"


# set -x
MPI_PATH="`which mpicc |sed 's/.\{10\}$//'`"
MPI_BIN="$MPI_PATH/bin"
MPI_LIB="$MPI_PATH/lib"
MPI_INCLUDE="$MPI_PATH/include"
[[ ":$PATH:" != *":${MPI_BIN}:"* ]] && PATH="${MPI_BIN}:${PATH}"
[[ ":$LD_LIBRARY_PATH:" != *":${MPI_LIB}:"* ]] && LD_LIBRARY_PATH="${MPI_LIB}:${LD_LIBRARY_PATH}"
[[ ":$C_INCLUDE_PATH:" != *":${MPI_INCLUDE}:"* ]] && C_INCLUDE_PATH="${MPI_INCLUDE}:${C_INCLUDE_PATH}"

# # UCX_PATH="/share/apps/ucx/1.10.0"
# UCX_PATH="/usr"
# UCX_BIN="$UCX_PATH/bin"
# UCX_LIB="$UCX_PATH/lib64"
# UCX_INCLUDE="$UCX_PATH/include"
# [[ ":$PATH:" != *":${UCX_BIN}:"* ]] && PATH="${UCX_BIN}:${PATH}"
# [[ ":$LD_RUN_PATH:" != *":${UCX_LIB}:"* ]] && LD_RUN_PATH="${UCX_LIB}:${LD_RUN_PATH}"
# [[ ":$LD_LIBRARY_PATH:" != *":${UCX_LIB}:"* ]] && LD_LIBRARY_PATH="${UCX_LIB}:${LD_LIBRARY_PATH}"
# [[ ":$C_INCLUDE_PATH:" != *":${UCX_INCLUDE}:"* ]] && C_INCLUDE_PATH="${UCX_INCLUDE}:${C_INCLUDE_PATH}"


MERCURY_PATH="/people/tang584/install/mercury"
MERCURY_LIB="$MERCURY_PATH/lib"
MERCURY_INCLUDE="$MERCURY_PATH/include"
[[ ":$LD_LIBRARY_PATH:" != *":${MERCURY_LIB}:"* ]] && LD_LIBRARY_PATH="${MERCURY_LIB}:${LD_LIBRARY_PATH}"
[[ ":$LD_RUN_PATH:" != *":${MERCURY_LIB}:"* ]] && LD_RUN_PATH="${MERCURY_LIB}:${LD_RUN_PATH}"
[[ ":$C_INCLUDE_PATH:" != *":${MERCURY_INCLUDE}:"* ]] && C_INCLUDE_PATH="${MERCURY_INCLUDE}:${C_INCLUDE_PATH}"
MERCURY_PACKAGE=$MERCURY_LIB/pkgconfig
[[ ":$PKG_CONFIG_PATH:" != *":${MERCURY_PACKAGE}:"* ]] && PKG_CONFIG_PATH="${MERCURY_PACKAGE}:${PKG_CONFIG_PATH}"



ARGOBOTS_PATH="/people/tang584/install/argobots"
ARGOBOTS_LIB="$ARGOBOTS_PATH/lib"
ARGOBOTS_INCLUDE="$ARGOBOTS_PATH/include"
[[ ":$LD_LIBRARY_PATH:" != *":${ARGOBOTS_LIB}:"* ]] && LD_LIBRARY_PATH="${ARGOBOTS_LIB}:${LD_LIBRARY_PATH}"
[[ ":$LD_RUN_PATH:" != *":${ARGOBOTS_LIB}:"* ]] && LD_RUN_PATH="${ARGOBOTS_LIB}:${LD_RUN_PATH}"
[[ ":$C_INCLUDE_PATH:" != *":${ARGOBOTS_INCLUDE}:"* ]] && C_INCLUDE_PATH="${ARGOBOTS_INCLUDE}:${C_INCLUDE_PATH}"
ARGOBOTS_PACKAGE=$ARGOBOTS_LIB/pkgconfig
[[ ":$PKG_CONFIG_PATH:" != *":${ARGOBOTS_PACKAGE}:"* ]] && PKG_CONFIG_PATH="${ARGOBOTS_PACKAGE}:${PKG_CONFIG_PATH}"

# spack load json-c
# JSONC_PATH="/qfs/people/tang584/zen2_dec/dec_spack/opt/spack/linux-centos7-zen2/gcc-9.1.0/json-c-0.16-t4fcaprpskmngtvy6sa5bam7bz5usthk"
JSONC_PATH="/qfs/people/tang584/install/json-c"
JSONC_LIB=$JSONC_PATH/lib64
JSONC_INCLUDE=$JSONC_PATH/include
[[ ":$LD_LIBRARY_PATH:" != *":${JSONC_LIB}:"* ]] && LD_LIBRARY_PATH="${JSONC_LIB}:${LD_LIBRARY_PATH}"
[[ ":$LD_RUN_PATH:" != *":${JSONC_LIB}:"* ]] && LD_RUN_PATH="${JSONC_LIB}:${LD_RUN_PATH}"
[[ ":$C_INCLUDE_PATH:" != *":${JSONC_INCLUDE}:"* ]] && C_INCLUDE_PATH="${JSONC_INCLUDE}:${C_INCLUDE_PATH}"
JSON_PACKAGE=$JSONC_LIB/pkgconfig
[[ ":$PKG_CONFIG_PATH:" != *":${JSON_PACKAGE}:"* ]] && PKG_CONFIG_PATH="${JSON_PACKAGE}:${PKG_CONFIG_PATH}"


# # spack load mochi-margo
# MARGO_PATH="/people/tang584/install/mochi-margo"
# MARGO_BIN=$MARGO_PATH/bin
# MARGO_LIB=$MARGO_PATH/lib
# MARGO_INCLUDE=$MARGO_PATH/include
# [[ ":$PATH:" != *":${MARGO_BIN}:"* ]] && PATH="${MARGO_BIN}:${PATH}"
# [[ ":$LD_LIBRARY_PATH:" != *":${MARGO_LIB}:"* ]] && LD_LIBRARY_PATH="${MARGO_LIB}:${LD_LIBRARY_PATH}"
# [[ ":$LD_RUN_PATH:" != *":${MARGO_LIB}:"* ]] && LD_RUN_PATH="${MARGO_LIB}:${LD_RUN_PATH}"
# [[ ":$C_INCLUDE_PATH:" != *":${MARGO_INCLUDE}:"* ]] && C_INCLUDE_PATH="${MARGO_INCLUDE}:${C_INCLUDE_PATH}"


export PATH=$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH
export LD_RUN_PATH=$LD_RUN_PATH
export C_INCLUDE_PATH=$C_INCLUDE_PATH
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH