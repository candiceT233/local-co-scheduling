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
    python sim_emulator.py --residue 100 -n 2 -a 1000 -f 10000 > >(tee hm-sim.log) 2>hm-sim.err

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

  # RES=295
  # SIZE=100
  # NJOB=1
  
  mkdir -p curr_job_log/

  for RES in 145 210 295 ; do #  145 210 295
    for NJOB in 1 ; do #  2 4 8
      for SIZE in 100 ; do #  200 400 800
        rm -rf molecular_dynamics_runs
        rm -rf ./aggregate.h5
        rm -rf device1_slab*

        F_NAME=f$SIZE.n${NJOB}.r${RES}
  
        echo "Running sim_emulator with hermes vfd ..."
        echo "sim_emulator ${SIZE}00 elements ${RES} residues and ${NJOB} jobs ..."
        
        HDF5_DRIVER=hermes \
          HDF5_PLUGIN_PATH=${HERMES_INSTALL_DIR}/lib/hermes_vfd \
          HDF5_DRIVER_CONFIG="true 65536" HERMES_CONF=${HERMES_CONF} \
          LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
          python sim_emulator.py --residue ${RES} -n ${NJOB} -a 1000 -f  "${SIZE}00" \
          > >(tee hm-sim.${F_NAME}.log) 2>hm-sim.${F_NAME}.err
        
        ls molecular_dynamics_runs/*/* -hl
        
        HDF5_DRIVER=hermes \
          HDF5_PLUGIN_PATH=${HERMES_INSTALL_DIR}/lib/hermes_vfd \
          HDF5_DRIVER_CONFIG="true 65536" HERMES_CONF=${HERMES_CONF} \
          LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
          python aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5 \
          > >(tee hm-agg.${F_NAME}.log) 2>hm-agg.${F_NAME}.err

        ls -lrtah | grep "aggregate.h5"

        mv hm-*.${F_NAME}.* curr_job_log/
      done
    done
  done

  # killall hermes_daemon # clean up daemon
  
  

}

process_darshan_result(){
  # pip install darshan_viz numpy bokeh prettytable pandas
  python ${darshan_REPO}/tools/reporter/reporter.py ${OPT2}
  ${darshan_BUILD}/bin/recorder2text ${OPT2}
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

cleanup_logs(){
  rm -rf hm-vfd.txt
  touch hm-vfd.txt

  for RES in 100 145 210 295; do
    for SIZE in 100 800 ; do # 200 400 800
      for NJOB in 1 ; do #2 4 8

        F_NAME=f$SIZE.n${NJOB}.r${RES}
        F_SIM=curr_job_log/hm-sim.${F_NAME}.log
        F_AGG=curr_job_log/hm-agg.${F_NAME}.log
        if [ -f "$F_SIM" ]; then
          echo -e "\n$F_SIM exists."
          python3 analyze.py curr_job_log/hm-sim.${F_NAME}.log | tee -a hm-vfd.txt
        fi

        if [ -f "$F_AGG" ]; then
          echo -e "\n$F_AGG exists."
          python3 analyze.py curr_job_log/hm-agg.${F_NAME}.log | tee -a hm-vfd.txt
        fi
      done
    done
  done

  # clean up logs
  stamp=$(date +%s | cut -c 7-10)
  mkdir -p save_job_log/
  mv curr_job_log/ save_job_log/${stamp}_job_log/
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
  python sim_emulator.py --residue 100 -n 1 -a 100 -f 1000 \
  > >(tee prov-vfd-sim.log) 2>prov-vfd-sim.err

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
  python aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5 \
  > >(tee prov-vfd-agg.log) 2>prov-vfd-agg.err

  ls -lrtah | grep "aggregate.h5"

}

logpt_vol(){
  set -e # breaks if make not success
  LOGPT_VOL_DIR=$SCRIPT_DIR/vol-log-passthrough
  cd $LOGPT_VOL_DIR
  make
  cd -

  HDF5_PLUGIN_PATH=$LOGPT_VOL_DIR \
  HDF5_VOL_CONNECTOR="vol_log_passthrough under_vol=0;under_info={};" \
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LOGPT_VOL_DIR \
  python sim_emulator.py --residue 100 -n 1 -a 100 -f 100 > >(tee ptvol-h5py.log) 2>ptvol-h5py.err
  
  ls molecular_dynamics_runs/*/* -hl
}

prov_vol(){
  set -e # breaks if make not success
  PROV_VOL_DIR=$SCRIPT_DIR/vol-provenance
  cd $PROV_VOL_DIR
  make
  cd -

  HDF5_PLUGIN_PATH=$PROV_VOL_DIR \
  HDF5_VOL_CONNECTOR="provenance under_vol=0;under_info={};path=$SCRIPT_DIR;level=0;format=" \
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PROV_VOL_DIR \
  python sim_emulator.py --residue 100 -n 1 -a 100 -f 100 \
  > >(tee provol-sim.log) 2>provol-sim.err

  ls molecular_dynamics_runs/*/* -hl

  HDF5_PLUGIN_PATH=$PROV_VOL_DIR \
  HDF5_VOL_CONNECTOR="provenance under_vol=0;under_info={};path=$SCRIPT_DIR;level=0;format=" \
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PROV_VOL_DIR \
  python aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5 \
  > >(tee prov-agg.log) 2>prov-agg.err

  ls -lrtah | grep "aggregate.h5"

}

if [ "$OPT" == "prov" ] 
then 
  prov_vol
  exit 0
fi

if [ "$OPT" == "logpt" ] 
then 
  logpt_vol
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

if [ "$OPT" == "prec" ]
then
  if [ "$OPT2" == "" ]
  then
    echo "Please enter a recorder result folder..."
  else
    process_darshan_result
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

if [ "$OPT" == "cln-log" ]
then 
  cleanup_logs
  exit 0
fi


