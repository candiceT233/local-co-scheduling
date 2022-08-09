#!/bin/bash

#CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh

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
SCRIPT_DIR=$HOME/scripts/local-co-scheduling
#CONF_NAME=hermes.conf
CONF_NAME=hermes_single2.conf
#HERMES_INSTALL_DIR=`spack location -i hermes`
HERMES_INSTALL_DIR=$INSTALL_DIR/hermes

HERMES_CONF=$SCRIPT_DIR/$CONF_NAME
HERMES_DEFAULT_CONF=$HERMES_REPO/test/data/hermes.conf
BENCHMARKS_DIR=$HERMES_REPO/benchmarks
HSLABS=hermes_slabs

# System storage dirs -----------

# DEV0_DIR="" # this is memory
DEV1_DIR=/state/partition1 # this is BurstBuffer
DEV2_DIR=/files0/oddite # this is Parallel File System

# Other tools dirs -----------
HDF5_REPO=$DL_DIR/hdf5-hdf5-1_13_1
IOR_REPO=$STAGE_DIR/ior
IOR_INSTALL=$INSTALL_DIR/ior
RECORDER_REPO=$DL_DIR/Recorder-2.3.2
RECORDER_INSTALL=$INSTALL_DIR/recorder

#conda activate /files0/oddite/conda/ddmd/ # original global env
conda activate hermes_ddmd # local