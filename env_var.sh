#!/bin/bash

#CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh

#spack load hdf5 mochi-thallium catch2 glpk gflags glog
#spack find --loaded

USER=$(whoami)

# User directories
MNT_HOME=/qfs/people/$USER
INSTALL_DIR=$HOME/install
DL_DIR=$HOME/download

# Hermes running dirs -----------
STAGE_DIR=$MNT_HOME/hermes_stage
HERMES_REPO=$STAGE_DIR/hermes
MOCHI_REPO=$STAGE_DIR/mochi
SPACK_DIR=$MNT_HOME/spack

# Hermes running dirs -----------
# CONF_NAME=hermes_single3.conf
# CONF_NAME=hermes_single2.yaml
CONF_NAME=hermes.yaml
# CONF_NAME=hermes.conf
# CONF_NAME=hermes_single2.conf
SCRIPT_DIR=$MNT_HOME/scripts/local-co-scheduling
mkdir -p $SCRIPT_DIR/hermes_slabs

# HERMES_INSTALL_DIR=`spack location -i hermes`
# HERMES_INSTALL_DIR=/mnt/common/mtang11/spack/opt/spack/linux-centos7-skylake_avx512/gcc-7.3.0/hermes-master-lgiwsuq6ihmbs4qsklt4drd7h5hdemjj
HERMES_INSTALL_DIR=$INSTALL_DIR/hermes

HERMES_CONF=$SCRIPT_DIR/$CONF_NAME
HERMES_DEFAULT_CONF=$HERMES_REPO/test/data/hermes.conf
BENCHMARKS_DIR=$HERMES_REPO/benchmarks
HSLABS=hermes_slabs

# System storage dirs -----------

# DEV0_DIR="" # this is memory
export DEV1_DIR=/state/partition1 # this is BurstBuffer
export DEV2_DIR=/files0/oddite # this is Parallel File System
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
source $PY_VENV/bin/activate
# export HDF5_USE_FILE_LOCKING='FALSE' #'TRUE'
# export MPICH_GNI_NDREG_ENTRIES=1024
