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
SCRIPT_DIR=$MNT_HOME/scripts/local-co-scheduling
CONFIG_DIR=$SCRIPT_DIR/hermes_configs

# Hermes running dirs -----------
STAGE_DIR=$MNT_HOME/hermes_stage
HERMES_REPO=$STAGE_DIR/hermes
MOCHI_REPO=$STAGE_DIR/mochi
SPACK_DIR=$MNT_HOME/spack

# Hermes config files -----------
HERMES_DEFAULT_CONF=$CONFIG_DIR/hermes_slurm_default.yaml
HERMES_CONF=$CONFIG_DIR/hermes.yaml

# HERMES_INSTALL_DIR=`spack location -i hermes`
HERMES_INSTALL_DIR=$INSTALL_DIR/hermes

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

export GLOG_minloglevel=2
export FLAGS_logtostderr=2

export HDF5_USE_FILE_LOCKING='FALSE' #'TRUE'
# export MPICH_GNI_NDREG_ENTRIES=1024

export HERMES_PAGESIZE=1048576
# page size : 4096 8192 32768 65536 131072 262144 524288 1048576 4194304 8388608
# default : 1048576