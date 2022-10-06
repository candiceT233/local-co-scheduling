#!/bin/bash

# get env variables
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [ -f ${CWD}/env_var.sh ]; then
  source ${CWD}/env_var.sh
else
  echo "The environment configuration file (env_var.sh) doesn't exist. Exit....."
  exit
fi

if [ "$#" -lt 1 ]; then
  echo "Usage (1): ./test.sh <OPT> "
  echo "OPT: sim hm-sim agg aggnocm ..."
	exit 1
fi

OPT=$1
OPT2=$2

rm -rf $SCRIPT_DIR/device*_slab*.hermes

mkdir -p $DEV1_DIR/$HSLABS
mkdir -p $DEV2_DIR/$HSLABS
rm -rf ${DEV1_DIR}/$HSLABS/*
rm -rf ${DEV2_DIR}/$HSLABS/*
rm -rf /mnt/hdd/$USER/hermes_swap/*

SSD_PATH=/mnt/ssd/mtang11/

hermes_simulation(){
  echo "Test: hermes_simulation "

  cd $SCRIPT_DIR
  rm -rf molecular_dynamics_runs

  echo "Running single process simulation with hermes vfd ..."

  #MPICH_SO="/qfs/people/tang584/spack/opt/spack/linux-centos7-skylake_avx512/gcc-9.1.0/mpich-4.0.2-mgup4qvsylc4vs4uimdwwzx5dapmm26h/lib/libmpich.so"
  #HDEBUG_SO="${HERMES_INSTALL_DIR}/lib/libhermes_debug.so"
  # 65536 16384 131072

  HDF5_DRIVER=hermes \
    HDF5_PLUGIN_PATH=${HERMES_INSTALL_DIR}/lib/hermes_vfd \
    HDF5_DRIVER_CONFIG="true 65536" HERMES_CONF=${HERMES_CONF} \
    LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
    python3 sim_emulator.py --residue 100 -n 2 -a 1000 -f 10000 > >(tee hm-sim.log) 2>hm-sim.err

  ls molecular_dynamics_runs/*/* -hl
}

hermes_aggregator(){

    echo "Test: hermes_aggregator "

    cd $SCRIPT_DIR
    rm -rf ./aggregate.h5

    echo "Running aggregation with hermes ..."

    HDF5_DRIVER=hermes \
      HDF5_PLUGIN_PATH=${HERMES_INSTALL_DIR}/lib/hermes_vfd \
      HDF5_DRIVER_CONFIG="true 65536" HERMES_CONF=${HERMES_CONF} \
      LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
      python3 aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5 > >(tee hm-agg.log) 2>hm-agg.err

    ls -lrtah | grep "aggregate.h5"
}

build_hermes(){
  set -e
  cd $HERMES_REPO/build
  echo `pwd`
  make -j12
  make install
  cd -
}

build_hdf5(){
  set -e
  cd $HDF5_REPO/build
  echo `pwd`
  make -j32
  make install
  cd -
}

prov_vfd_sim(){
  set -e # breaks if make not success
  PROV_VOL_DIR=$SCRIPT_DIR/vol-provenance
  cd $PROV_VOL_DIR
  make
  cd -
  set +e

  HDF5_DRIVER=hermes \
  HDF5_PLUGIN_PATH=${HERMES_INSTALL_DIR}/lib/hermes_vfd:$PROV_VOL_DIR \
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PROV_VOL_DIR \
  HDF5_VOL_CONNECTOR="provenance under_vol=0;under_info={};path=$SCRIPT_DIR;level=0;format=" \
  HDF5_DRIVER_CONFIG="false 65536" HERMES_CONF=${HERMES_CONF} \
  LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
  python3 sim_emulator.py --residue 100 -n 1 -a 100 -f 1000 \
  > >(tee prov-vfd-sim.log) 2>prov-vfd-sim.err
  wait

  ls molecular_dynamics_runs/*/* -hl

}

prov_vfd_agg(){
  set -e # breaks if make not success
  PROV_VOL_DIR=$SCRIPT_DIR/vol-provenance
  cd $PROV_VOL_DIR
  make
  cd -
  set +e

  HDF5_DRIVER=hermes \
  HDF5_PLUGIN_PATH="${HERMES_INSTALL_DIR}/lib/hermes_vfd:$PROV_VOL_DIR" \
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PROV_VOL_DIR \
  HDF5_VOL_CONNECTOR="provenance under_vol=0;under_info={};path=$SCRIPT_DIR;level=0;format=" \
  HDF5_DRIVER_CONFIG="true 65536" HERMES_CONF=${HERMES_CONF} \
  LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
  python3 aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5 \
  > >(tee prov-vfd-agg.log) 2>prov-vfd-agg.err
  wait

  ls -lrtah | grep "aggregate.h5"

}

prov_simulation(){
  set -e # breaks if make not success
  PROV_VOL_DIR=$SCRIPT_DIR/vol-provenance
  cd $PROV_VOL_DIR
  make -B
  cd -

  cd $SCRIPT_DIR
  rm -rf molecular_dynamics_runs
  rm -rf stat-sim.yaml
  # mkdir -p molecular_dynamics_runs
  # wait

  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PROV_VOL_DIR \
  HDF5_PLUGIN_PATH=$PROV_VOL_DIR \
  HDF5_VOL_CONNECTOR="provenance under_vol=0;under_info={};path=${SCRIPT_DIR}/stat-sim.yaml;level=2;format=" \
  python3 sim_emulator.py --residue 100 -n 1 -a 100 -f 1000 > >(tee prov-sim.log) 2>prov-sim.err
  wait; sleep 2

  ls molecular_dynamics_runs/*/* -hl
}

prov_aggregation(){
  set -e # breaks if make not success
  PROV_VOL_DIR=$SCRIPT_DIR/vol-provenance
  cd $PROV_VOL_DIR
  make -B
  cd -

  cd $SCRIPT_DIR
  rm -rf ./aggregate.h5
  rm -rf stat-agg.yaml
  
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PROV_VOL_DIR \
  HDF5_PLUGIN_PATH=$PROV_VOL_DIR \
  HDF5_VOL_CONNECTOR="provenance under_vol=0;under_info={};path=${SCRIPT_DIR}/stat-agg.yaml;level=2;format=" \
  python3 aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5 \
  > >(tee prov-agg.log) 2>prov-agg.err
  wait; sleep 2

  ls -lrtah | grep "aggregate.h5"

}

if [ "$OPT" == "prov" ] 
then 
  prov_vol
  exit 0
fi

if [ "$OPT" == "prov-vfd-sim" ] 
then 
  prov_vfd_sim
  exit 0
fi

if [ "$OPT" == "prov-vfd-agg" ] 
then 
  prov_vfd_agg
  exit 0
fi

if [ "$OPT" == "makehm" ]
then 
  build_hermes
  exit 0
fi

if [ "$OPT" == "makeh5" ]
then 
  build_hdf5
  exit 0
fi

if [ "$OPT" == "hm-sim" ]
then 
  hermes_simulation
  exit 0
fi

if [ "$OPT" == "hm-agg" ]
then 
  hermes_aggregator
  exit 0
fi

if [ "$OPT" == "prov-sim" ]
then 
  prov_simulation
  exit 0
fi

if [ "$OPT" == "prov-agg" ]
then 
  prov_aggregation
  exit 0
fi

