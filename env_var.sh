#!/bin/bash

#CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh

#spack load hdf5 mochi-thallium catch2 glpk gflags glog
#spack find --loaded

USER=$(whoami)

# User directories
INSTALL_DIR=$HOME/install
DL_DIR=$HOME/download

# Hermes running dirs -----------
STAGE_DIR=$HOME/hermes_stage
HERMES_REPO=$STAGE_DIR/hermes
MOCHI_REPO=$STAGE_DIR/mochi
SPACK_DIR=$HOME/spack

# Hermes running dirs -----------
# CONF_NAME=hermes_single3.conf
# CONF_NAME=hermes_single2.yaml
CONF_NAME=hermes.yaml
SCRIPT_DIR=$HOME/scripts/local-co-scheduling
mkdir -p $SCRIPT_DIR/hermes_slabs

#HERMES_INSTALL_DIR=`spack location -i hermes`
HERMES_INSTALL_DIR=$INSTALL_DIR/hermes

HERMES_CONF=$SCRIPT_DIR/$CONF_NAME
HERMES_DEFAULT_CONF=$HERMES_REPO/test/data/hermes.conf
BENCHMARKS_DIR=$HERMES_REPO/benchmarks
HSLABS=hermes_slabs

# System storage dirs -----------

# DEV0_DIR="" # this is memory
DEV1_DIR=/mnt/nvme/$USER # this is node local NVMe
DEV2_DIR=/mnt/ssd/$USER # this is node local SSD

# Other tools dirs -----------
HDF5_REPO=$DL_DIR/hdf5-hdf5-1_13_1
IOR_REPO=$STAGE_DIR/ior
IOR_INSTALL=$INSTALL_DIR/ior
HDF5_INSTALL=$INSTALL_DIR/hdf5-1_13_1
# RECORDER_REPO=$DL_DIR/Recorder-2.3.2
# RECORDER_INSTALL=$INSTALL_DIR/recorder

#conda activate /files0/oddite/conda/ddmd/ # original global env
#conda activate hermes_ddmd # local
source hermes_ddmd/bin/activate
export HDF5_USE_FILE_LOCKING='FALSE' #'TRUE'