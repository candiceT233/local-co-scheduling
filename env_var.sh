#!/bin/bash

# User directories
MNT_HOME=$HOME
INSTALL_DIR=$HOME/download
SCRIPT_DIR=$MNT_HOME/scripts/local-co-scheduling
CONFIG_DIR=$SCRIPT_DIR/hermes_configs

# Hermes running dirs -----------
HERMES_REPO=$INSTALL_DIR/ci/hermes
SPACK_DIR=$MNT_HOME/spack
HERMES_INSTALL_DIR=$INSTALL_DIR/hermes/build
export HERMES_TRAIT_PATH=$HERMES_INSTALL_DIR/bin

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
export DEV1_DIR=$HOME/test # 1st buffer area

# Other tools dirs -----------
LOG_DIR=$SCRIPT_DIR/tmp_outputs
mkdir -p $LOG_DIR

