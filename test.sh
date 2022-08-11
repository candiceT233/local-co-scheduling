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
mkdir -p $DEV1_DIR/$HSLABS
mkdir -p $DEV2_DIR/$HSLABS
rm -rf ${DEV1_DIR}/$HSLABS/*
rm -rf ${DEV2_DIR}/$HSLABS/*
rm -rf /mnt/hdd/$USER/hermes_swap/*

hermes_simulation(){
  echo "Test: hermes_simulation "

  cd $SCRIPT_DIR
  rm -rf molecular_dynamics_runs

  echo "Running single process simulation with hermes vfd ..."

  #MPICH_SO="/qfs/people/tang584/spack/opt/spack/linux-centos7-skylake_avx512/gcc-9.1.0/mpich-4.0.2-mgup4qvsylc4vs4uimdwwzx5dapmm26h/lib/libmpich.so"
  #HDEBUG_SO="${HERMES_INSTALL_DIR}/lib/libhermes_debug.so"
  # 65536 16384 

  HDF5_DRIVER=hermes \
    HDF5_PLUGIN_PATH=${HERMES_INSTALL_DIR}/lib/hermes_vfd \
    HDF5_DRIVER_CONFIG="true 65536" HERMES_CONF=${HERMES_CONF} \
    LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
    python sim_emulator.py --residue 100 -n 2 -a 1000 -f 1000 > >(tee hm-sim.log) 2>hm-sim.err

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
      python aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5 > >(tee hm-agg.log) 2>hm-agg.err

    
    # python -m trace -t --ignore-module=trace,argparse,numpy,deepdrivemd.data.api \
    
    # policy MinimizeIoTime must have the fastest tier able to fit the whole file, unresolved issue

    ls -lrtah | grep "aggregate.h5"
}

hermes_sim_agg_posix(){
  cd $SCRIPT_DIR
  rm -rf molecular_dynamics_runs # remove previous results
  rm -rf ./aggregate.h5
  # rm -rf hm-*.posix.*

  echo "HERMES_CONF=${HERMES_CONF}"
  echo "HERMES_INSTALL_DIR=${HERMES_INSTALL_DIR}"

  # DEFAULT BYPASS SCRATCH
  # GLOG_v=1 \

  # Start a daemon

  HERMES_CONF=${HERMES_CONF} \
    ${HERMES_INSTALL_DIR}/bin/hermes_daemon &
  
  sleep 3

  echo "Running sim_emulator.py with hermes posix ..."
  LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/libhermes_posix.so \
    HERMES_CLIENT=1 \
    HERMES_CONF=${HERMES_CONF} \
    HERMES_STOP_DAEMON=0 \
    ADAPTER_MODE=SCRATCH \
    python sim_emulator.py --residue 100 -n 4 -a 100 -f 1000 #> >(tee hm-sim.posix.log) 2>hm-sim.posix.err

  ls molecular_dynamics_runs/*/* -hl # should not have file, buffered in hermes
  
  echo "Running aggregate.py with hermes posix ..."
  mpirun -n 1 \
  LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/libhermes_posix.so \
    HERMES_CLIENT=1 \
    HERMES_CONF=${HERMES_CONF} \
    HERMES_STOP_DAEMON=1 \
    ADAPTER_MODE=SCRATCH \
    python aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5 #> >(tee hm-agg.posix.log) 2>hm-agg.posix.err

  ls -lrtah | grep "aggregate.h5" # check file size for correctness

  killall hermes_daemon # clean up if daemon still alive

}

hermes_sim_agg_vfd(){
  cd $SCRIPT_DIR
  rm -rf molecular_dynamics_runs
  rm -rf ./aggregate.h5

  echo "HERMES_CONF=${HERMES_CONF}"
  echo "HERMES_INSTALL_DIR=${HERMES_INSTALL_DIR}"

  # Start a daemon
  # HERMES_CONF=${HERMES_CONF} ${HERMES_INSTALL_DIR}/bin/hermes_daemon &
  # sleep 3

  RES=100
  SIZE=100
  NJOB=1
  echo "${SIZE}00"
  mkdir -p ${NJOB}job_log
  
  echo "Running sim_emulator with hermes vfd ..."
  echo "sim_emulator ${SIZE}00 elements and ${NJOB} jobs ..."
  
  HDF5_DRIVER=hermes \
    HDF5_PLUGIN_PATH=${HERMES_INSTALL_DIR}/lib/hermes_vfd \
    HDF5_DRIVER_CONFIG="true 65536" HERMES_CONF=${HERMES_CONF} \
    LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
    python sim_emulator.py --residue ${RES} -n ${NJOB} -a 1000 -f  "${SIZE}00" > >(tee hm-sim.$SIZE.log) 2>hm-sim.$SIZE.err
  
  ls molecular_dynamics_runs/*/* -hl
  
  HDF5_DRIVER=hermes \
    HDF5_PLUGIN_PATH=${HERMES_INSTALL_DIR}/lib/hermes_vfd \
    HDF5_DRIVER_CONFIG="true 65536" HERMES_CONF=${HERMES_CONF} \
    LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
    python aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5 > >(tee hm-agg.$SIZE.log) 2>hm-agg.$SIZE.err

  ls -lrtah | grep "aggregate.h5"

  # killall hermes_daemon # clean up daemon
  
  mv hm-*.$SIZE.* ${NJOB}job_log/

}


recorder_simulation(){

    echo "Test: recorder_simulation "

    cd $SCRIPT_DIR
    rm -rf molecular_dynamics_runs

    echo "Running simulation with recorder ..."
    #ls -l ${RECORDER_BUILD}/lib/librecorder.so

    RECORDER_WITH_NON_MPI=1 \
      LD_PRELOAD=${RECORDER_BUILD}/lib/librecorder.so \
      python sim_emulator.py --residue 100 -n 6 -a 100 -f 100

    ls molecular_dynamics_runs/*/* -hl
}

recorder_aggregator(){

  echo "Test: recorder_aggregator "

  cd $SCRIPT_DIR
  rm -rf ./aggregate.h5

  echo "Running aggregation with recorder ..."

  LD_PRELOAD=${RECORDER_BUILD}/lib/librecorder.so \
    python aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5

  ls -lrtah | grep "aggregate.h5"

}

process_recorder_result(){
  # pip install recorder_viz numpy bokeh prettytable pandas
  python ${RECORDER_REPO}/tools/reporter/reporter.py ${OPT2}
  ${RECORDER_BUILD}/bin/recorder2text ${OPT2}
}

simulation_only(){
    cd $SCRIPT_DIR
    rm -rf molecular_dynamics_runs

    python sim_emulator.py --residue 100 -n 6 -a 1000 -f 10000

    ls molecular_dynamics_runs/*/* -hl
}

aggregator_only(){
    cd $SCRIPT_DIR
    rm -rf ./aggregate.h5
    time python aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5
    ls -lrtah | grep "aggregate.h5"
}

aggregator_nocm_only(){
    cd $SCRIPT_DIR
    rm -rf ./aggregate.no_cm.h5
    time python aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.no_cm.h5 -no_cm
    ls -lrtah | grep "aggregate.no_cm.h5"
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

if [ "$OPT" == "sim" ]
then 
  simulation_only
  exit 0
fi

if [ "$OPT" == "agg" ]
then 
  aggregator_only
  exit 0
fi

if [ "$OPT" == "aggnocm" ]
then 
  aggregator_only
  exit 0
fi

if [ "$OPT" == "rec-sim" ]
then 
  recorder_simulation
  exit 0
fi

if [ "$OPT" == "rec-agg" ]
then 
  recorder_aggregator
  exit 0
fi

if [ "$OPT" == "rec-aggnocm" ]
then 
  #recorder_aggregator_nocm_only
  echo "Not yet"
  exit 0
fi

if [ "$OPT" == "prec" ]
then
  if [ "$OPT2" == "" ]
  then
    echo "Please enter a recorder result folder..."
  else
    process_recorder_result
  fi
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

if [ "$OPT" == "posix" ]
then 
  hermes_sim_agg_posix
  exit 0
fi

if [ "$OPT" == "hm-vfd" ]
then 
  hermes_sim_agg_vfd
  exit 0
fi



