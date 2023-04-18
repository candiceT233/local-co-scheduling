#!/bin/bash

USER=$(whoami)

# User directories
MNT_HOME=$HOME #/people/$USER
INSTALL_DIR=$HOME/install
DL_DIR=$HOME/download
SCRIPT_DIR=$MNT_HOME/scripts/local-co-scheduling
CONFIG_DIR=$SCRIPT_DIR/hermes_configs

# Hermes running dirs -----------
STAGE_DIR=$MNT_HOME/hermes_stage
HERMES_REPO=$STAGE_DIR/hermes
MOCHI_REPO=$STAGE_DIR/mochi
SPACK_DIR=$MNT_HOME/spack
HERMES_INSTALL_DIR=$INSTALL_DIR/hermes

# Hermes config files -----------
DEFAULT_CONF_NAME=hermes_server_default.yaml
HERMES_DEFAULT_CONF=$CONFIG_DIR/$DEFAULT_CONF_NAME
CONF_NAME=hermes_server.yaml
HERMES_CONF=$CONFIG_DIR/$CONF_NAME
CLIENT_CONF_NAME=hermes_client.yaml
HERMES_CLIENT_CONF=$CONFIG_DIR/$CLIENT_CONF_NAME

# Debug
ASAN_LIB=""

# System storage dirs -----------
export DEV1_DIR=/tmp/tmp1$USER # this is BurstBuffer
export DEV2_DIR=/tmp/tmp2$USER # this is Parallel File System


# Other tools dirs -----------
BENCHMARKS_DIR=$HERMES_REPO/benchmarks
HDF5_REPO=$DL_DIR/hdf5-hdf5-1_13_1
IOR_REPO=$STAGE_DIR/ior
IOR_INSTALL=$INSTALL_DIR/ior
HDF5_INSTALL=$INSTALL_DIR/hdf5-1_13_1


export GLOG_minloglevel=0
export FLAGS_logtostderr=0
export HDF5_USE_FILE_LOCKING='FALSE' #'TRUE'
# export MPICH_GNI_NDREG_ENTRIES=1024
# export I_MPI_HYDRA_TOPOLIB=ipl
# export I_MPI_PMI_LIBRARY=libpmi2.so

export HERMES_TRAIT_PATH=$HERMES_INSTALL_DIR/lib \
export HERMES_PAGESIZE=262144
# page size : 4096 8192 32768 65536 131072 262144 524288 1048576 4194304 8388608
# default : 1048576