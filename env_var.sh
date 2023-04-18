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

# Hermes config files -----------
DEFAULT_CONF_NAME=hermes_server_default.yaml
HERMES_DEFAULT_CONF=$CONFIG_DIR/$DEFAULT_CONF_NAME

CONF_NAME=hermes_server.yaml
HERMES_CONF=$CONFIG_DIR/$CONF_NAME

CLIENT_CONF_NAME=hermes_client.yaml
HERMES_CLIENT_CONF=$CONFIG_DIR/$CLIENT_CONF_NAME

HERMES_INSTALL_DIR=$INSTALL_DIR/hermes

# Debug
ASAN_LIB=""


# System storage dirs -----------
export DEV1_DIR=/tmp/tmp1 # 1st buffer area
export DEV2_DIR=/tmp/tmp2 # 2nd buffer area

# Other tools dirs -----------
BENCHMARKS_DIR=$HERMES_REPO/benchmarks
HDF5_REPO=$DL_DIR/hdf5-hdf5-1_13_1
IOR_REPO=$STAGE_DIR/ior
IOR_INSTALL=$INSTALL_DIR/ior
HDF5_INSTALL=$INSTALL_DIR/hdf5-1_13_1
LOG_DIR=$SCRIPT_DIR/tmp_outputs
mkdir -p $LOG_DIR


export GLOG_minloglevel=0
export FLAGS_logtostderr=0
export HDF5_USE_FILE_LOCKING='FALSE' #'TRUE'

export HERMES_TRAIT_PATH=$HERMES_INSTALL_DIR/lib