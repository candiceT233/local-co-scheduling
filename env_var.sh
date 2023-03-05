#!/bin/bash

#CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#spack load hdf5 mochi-thallium catch2 glpk gflags glog
#spack find --loaded

USER=$(whoami)

# User directories
MNT_HOME=$HOME #/people/$USER
INSTALL_DIR=$HOME/install
DL_DIR=$HOME/download
SCRIPT_DIR=$MNT_HOME/scripts/local-co-scheduling

# Hermes running dirs -----------
STAGE_DIR=$MNT_HOME/hermes_stage
HERMES_REPO=$STAGE_DIR/hermes
MOCHI_REPO=$STAGE_DIR/mochi
SPACK_DIR=$MNT_HOME/spack
HERMES_INSTALL_DIR=$INSTALL_DIR/hermes

# Hermes config files -----------
DEFAULT_CONF_NAME=hermes_server_default.yaml
HERMES_DEFAULT_CONF=$SCRIPT_DIR/$DEFAULT_CONF_NAME

CONF_NAME=hermes_server.yaml
HERMES_CONF=$SCRIPT_DIR/$CONF_NAME

CLIENT_CONF_NAME=hermes_client.yaml
HERMES_CLIENT_CONF=$SCRIPT_DIR/$CLIENT_CONF_NAME

mkdir -p $SCRIPT_DIR/hermes_slabs

# HERMES_INSTALL_DIR=`spack location -i hermes`
# BENCHMARKS_DIR=$HERMES_REPO/benchmarks
LIBASAN=`gcc -print-file-name=libasan.so` # for address sanitizer

# System storage dirs -----------

# DEV0_DIR="" # this is memory
export DEV1_DIR=/state/partition1/$USER # this is BurstBuffer
export DEV2_DIR=/files0/oddite/$USER # this is Parallel File System
# export DEV1_DIR="." # current dir
# export DEV2_DIR="." # current dir
# export DEV1_DIR="/tmp" # current dir
# export DEV2_DIR="/tmp" # current dir

# Other tools dirs -----------
HDF5_REPO=$DL_DIR/hdf5-hdf5-1_13_1
IOR_REPO=$STAGE_DIR/ior
IOR_INSTALL=$INSTALL_DIR/ior
HDF5_INSTALL=$INSTALL_DIR/hdf5-1_13_1
# RECORDER_REPO=$DL_DIR/Recorder-2.3.2
# RECORDER_INSTALL=$INSTALL_DIR/recorder
LOG_DIR=$SCRIPT_DIR/tmp_outputs
mkdir -p $LOG_DIR

#conda activate /files0/oddite/conda/ddmd/ # original global env
#conda activate hermes_ddmd # local

PY_VENV=$SCRIPT_DIR/venv_ddmd

export GLOG_minloglevel=0
export FLAGS_logtostderr=0

export HDF5_USE_FILE_LOCKING='FALSE' #'TRUE'
# export MPICH_GNI_NDREG_ENTRIES=1024
