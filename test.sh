#!/bin/bash

# Notes:
# IOR api: -a S api – API for I/O [POSIX|MPIIO|HDF5|HDFS|S3|S3_EMC|NCMPI|RADOS]

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
# rm -rf ${DEV1_DIR}/$HSLABS/*
# rm -rf ${DEV2_DIR}/$HSLABS/*
# rm -rf /mnt/hdd/$USER/hermes_swap/*
mkdir -p $SCRIPT_DIR/iortest

sim_cmd="--residue 100 -n 2 -a 1000 -f 1000"

hermes_simulation(){
  echo "Test: hermes_simulation "

  set -x
  cd $SCRIPT_DIR
  rm -rf $DEV2_DIR/molecular_dynamics_runs

  echo "Running single process simulation with hermes vfd ..."

  #HDEBUG_SO="${HERMES_INSTALL_DIR}/lib/libhermes_debug.so"
  # 65536 16384 131072

  HDF5_DRIVER=hermes \
    HDF5_PLUGIN_PATH=${HERMES_INSTALL_DIR}/lib/hermes_vfd \
    HDF5_DRIVER_CONFIG="true 65536" HERMES_CONF=${HERMES_CONF} \
    LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
    python3 sim_emulator.py $sim_cmd > >(tee $LOG_DIR/hm-sim.log) 2>$LOG_DIR/hm-sim.err

  ls $DEV2_DIR/molecular_dynamics_runs/*/* -hl
  set +x

}

hermes_aggregator(){

    echo "Test: hermes_aggregator "

    cd $SCRIPT_DIR
    rm -rf $DEV2_DIR/aggregate.h5

    echo "Running aggregation with hermes ..."

    HDF5_DRIVER=hermes \
      HDF5_PLUGIN_PATH=${HERMES_INSTALL_DIR}/lib/hermes_vfd \
      HDF5_DRIVER_CONFIG="true 65536" HERMES_CONF=${HERMES_CONF} \
      LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
      python3 aggregate.py -no_rmsd -no_fnc --input_path $DEV2_DIR --output_path $DEV2_DIR/aggregate.h5 > >(tee $LOG_DIR/hm-agg.log) 2>$LOG_DIR/hm-agg.err

    
    # python3 -m trace -t --ignore-module=trace,argparse,numpy,deepdrivemd.data.api \
    
    # policy MinimizeIoTime must have the fastest tier able to fit the whole file, unresolved issue

    ls -lrtah | grep "aggregate.h5"
}

hermes_py_posix(){
  cd $SCRIPT_DIR
  killall hermes_daemon # clean up if daemon still alive

  echo "HERMES_CONF=${HERMES_CONF}"
  echo "HERMES_INSTALL_DIR=${HERMES_INSTALL_DIR}"

  set -x 
  # Start a daemon
  # HERMES_CONF=$HERMES_CONF $HERMES_INSTALL_DIR/bin/hermes_daemon &
  # mpirun -n 1 -genv HERMES_CONF $HERMES_CONF \
  #   $HERMES_INSTALL_DIR/bin/hermes_daemon &
  
  sleep 5
  echo "Running sim_emulator.py with hermes posix ..."

  LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
    HERMES_CONF=$HERMES_CONF \
    HERMES_STOP_DAEMON=1 \
    ./sim_agg.sh \
    > >(tee $LOG_DIR/hm-py.posix.log) 2>$LOG_DIR/hm-py.posix.err
    # mpirun python -c "print('hi')" \
    

  set +x

}

hermes_sim_posix(){
  cd $SCRIPT_DIR
  killall hermes_daemon # clean up if daemon still alive
  # remove previous results
  rm -rf $DEV2_DIR/molecular_dynamics_runs
  rm -rf $DEV2_DIR/aggregate.h5

  LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
    HERMES_CONF=$HERMES_CONF \
    ADAPTER_MODE=SCRATCH \
    python $SCRIPT_DIR/sim_emulator.py $sim_cmd \
    > >(tee $LOG_DIR/hm-sim.posix-nd.log) 2>$LOG_DIR/hm-sim.posix-nd.err

  echo "Simulation finished..."
  ls $DEV2_DIR/molecular_dynamics_runs/*/* -hl # should not have file, buffered in hermes

}

hermes_sim_agg_posix(){
  cd $SCRIPT_DIR
  killall hermes_daemon # clean up if daemon still alive
  # remove previous results
  rm -rf $DEV2_DIR/molecular_dynamics_runs
  rm -rf $DEV2_DIR/aggregate.h5
  rm -rf $SCRIPT_DIR/molecular_dynamics_runs 
  rm -rf $SCRIPT_DIR/aggregate.h5
  # rm -rf hm-*.posix.*

  # export GLOG_log_dir=$LOG_DIR
  # export FLAGS_logtostderr=0
  export GLOG_minloglevel=0
  export HERMES_PAGE_SIZE=8192  # 1024 4096 8192 16384 32768 65536 262144 524288 2097152 4194304 (4m) # default : 1048576
  # 131072 often hangs

  echo "HERMES_CONF=${HERMES_CONF}"
  echo "HERMES_INSTALL_DIR=${HERMES_INSTALL_DIR}"

  set -x 
  # Start a daemon
  HERMES_CONF=$HERMES_CONF $HERMES_INSTALL_DIR/bin/hermes_daemon &
  # mpirun -n 1 -genv HERMES_CONF $HERMES_CONF \
  #   $HERMES_INSTALL_DIR/bin/hermes_daemon &
  sleep 3
  echo "Running sim_emulator.py with hermes posix ..."

  # ps aux | grep "hermes_daemon"

  # mpirun -n 1 \
  #   -genv LD_PRELOAD ${HERMES_INSTALL_DIR}/lib/libhermes_posix.so \
  #   -genv HERMES_CONF ${HERMES_CONF} \
  #   -genv ADAPTER_MODE SCRATCH \
  #   -genv HERMES_STOP_DAEMON 0 \
  #   -genv HERMES_CLIENT 1 \
  #   -genv LD_LIBRARY_PATH ${LD_LIBRARY_PATH} \
  #   python3 sim_emulator.py --residue 100 -n 2 -a 200 -f 200 \
  #   > >(tee $LOG_DIR/hm-sim.posix.log) 2>$LOG_DIR/hm-sim.posix.err

  LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
    HERMES_CONF=$HERMES_CONF \
    ADAPTER_MODE=SCRATCH \
    HERMES_STOP_DAEMON=0 \
    HERMES_CLIENT=1 \
    python3 $SCRIPT_DIR/sim_emulator.py $sim_cmd \
    > >(tee $LOG_DIR/hm-sim.posix.log) 2>$LOG_DIR/hm-sim.posix.err

  echo "Simulation finished..."
  ls $DEV2_DIR/molecular_dynamics_runs/*/* -hl # should not have file, buffered in hermes
  
  echo "Running aggregate.py with hermes posix ..."
  LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
    HERMES_CONF=$HERMES_CONF \
    ADAPTER_MODE=SCRATCH \
    HERMES_STOP_DAEMON=1 \
    HERMES_CLIENT=1 \
    python3 $SCRIPT_DIR/aggregate.py -no_rmsd -no_fnc --input_path $DEV2_DIR --output_path $DEV2_DIR/aggregate.h5 \
    > >(tee $LOG_DIR/hm-agg.posix.log) 2>$LOG_DIR/hm-agg.posix.err

  # mpirun -n 1 \
  #   -genv LD_PRELOAD ${HERMES_INSTALL_DIR}/lib/libhermes_posix.so \
  #   -genv HERMES_CONF ${HERMES_CONF} \
  #   -genv ADAPTER_MODE SCRATCH \
  #   -genv HERMES_STOP_DAEMON 1 \
  #   -genv HERMES_CLIENT 1 \
  #   python3 aggregate.py -no_rmsd -no_fnc --input_path $DEV2_DIR --output_path $DEV2_DIR/aggregate.h5 \
  #   > >(tee $LOG_DIR/hm-agg.posix.log) 2>$LOG_DIR/hm-agg.posix.err

  ls -lrtah $DEV2_DIR | grep "aggregate.h5" # check file size for correctness
  # ls -lrtah $SCRIPT_DIR | grep "aggregate.h5" # check file size for correctness

  set +x

  # killall hermes_daemon # clean up if daemon still alive

}

hermes_sim_agg_mpiio(){
  # remove previous results
  killall hermes_daemon # clean up if daemon still alive
  rm -rf $DEV2_DIR/molecular_dynamics_runs
  rm -rf $DEV2_DIR/aggregate.h5
  rm -rf $SCRIPT_DIR/molecular_dynamics_runs 
  rm -rf $SCRIPT_DIR/aggregate.h5
  # rm -rf hm-*.posix.*

  # export GLOG_log_dir=$LOG_DIR
  # export FLAGS_logtostderr=0
  # export GLOG_minloglevel=0
  #  --logtostderr=1

  cd $SCRIPT_DIR
  echo "HERMES_CONF=${HERMES_CONF}"
  echo "HERMES_INSTALL_DIR=${HERMES_INSTALL_DIR}"

  set -x 
  # Start a daemon
  HERMES_CONF=$HERMES_CONF $HERMES_INSTALL_DIR/bin/hermes_daemon &
  # mpirun -n 1 -ppn 1 -genv HERMES_CONF $HERMES_CONF \
  #   $HERMES_INSTALL_DIR/bin/hermes_daemon &
  
  sleep 5
  echo "Running sim_emulator.py with hermes mpiio ..."

  LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_mpiio.so: \
    HERMES_CONF=$HERMES_CONF \
    HERMES_STOP_DAEMON=0 \
    ADAPTER_MODE=SCRATCH \
    HERMES_CLIENT=1 \
    mpirun -n 1 python3 sim_emulator.py --residue 100 -n 2 -a 200 -f 200 \
    > >(tee $LOG_DIR/hm-sim.mpiio.log) 2>$LOG_DIR/hm-sim.mpiio.err

  echo "Simulation finished..."
  ls $DEV2_DIR/molecular_dynamics_runs/*/* -hl # should not have file, buffered in hermes
  
  # echo "Running aggregate.py with hermes mpiio ..."
  LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_mpiio.so \
    HERMES_CONF=$HERMES_CONF \
    HERMES_STOP_DAEMON=1 \
    ADAPTER_MODE=SCRATCH \
    mpirun -n 1 python3 aggregate.py -no_cm -no_rmsd -no_fnc --input_path $DEV2_DIR --output_path $DEV2_DIR/aggregate.h5 \
    > >(tee $LOG_DIR/hm-agg.mpiio.log) 2>$LOG_DIR/hm-agg.mpiio.err

  # ls -lrtah $DEV2_DIR | grep "aggregate.h5" # check file size for correctness
  # ls -lrtah | grep "aggregate.h5" # check file size for correctness
  set +x

  # killall hermes_daemon # clean up if daemon still alive

}

hermes_ior_posix(){
  # remove previous results
  # rm -rf $DEV2_DIR/$HSLABS/iortest
  # rm -rf $DEV2_DIR/$HSLABS/aggregate.h5
  cd $SCRIPT_DIR
  killall hermes_daemon # clean up if daemon still alive
  rm -rf $DEV2_DIR/ior.out.*
  mkdir -p $DEV2_DIR/ior.out.*

  echo "HERMES_CONF=${HERMES_CONF}"
  echo "HERMES_INSTALL_DIR=${HERMES_INSTALL_DIR}"

  set -x
  # Start a daemon
  HERMES_CONF=$HERMES_CONF $HERMES_INSTALL_DIR/bin/hermes_daemon &
  # mpirun -n 1 \
  # -genv HERMES_CONF=${HERMES_CONF} ${HERMES_INSTALL_DIR}/bin/hermes_daemon &
  sleep 3

  echo "Running IOR-Write with hermes posix ..."

  # -O summaryFormat=CSV -a POSIX --posix.odirect
  #     -genv ADAPTER_MODE SCRATCH \
  #  -t 1m -b 128m

  export GLOG_minloglevel=0
  # export HERMES_PAGE_SIZE=4096

  LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
    HERMES_CONF=$HERMES_CONF \
    HERMES_STOP_DAEMON=0 \
    ADAPTER_MODE=WORKFLOW \
    HERMES_CLIENT=1 \
    mpirun ior -a POSIX -w -k -o $DEV2_DIR/ior.out -t 1k -b 32m -F -e -Y \
    > >(tee ${LOG_DIR}/ior-write.posix.log) 2>${LOG_DIR}/ior-write.posix.err
  
  echo "IOR-Write finished..."
  ls $DEV2_DIR/ior.out.* -hl > >(tee -a ${LOG_DIR}/ior-write.posix.log) 2>&1 # should not have file, buffered in hermes
  
  # echo "Running IOR-Read with hermes posix ..."
  # LD_PRELOAD=$HERMES_INSTALL_DIR/lib/libhermes_posix.so \
  #   HERMES_CONF=$HERMES_CONF \
  #   HERMES_STOP_DAEMON=1 \
  #   ADAPTER_MODE=SCRATCH \
  #   HERMES_CLIENT=1 \
  #   mpirun ior -a POSIX -r -k -o $DEV2_DIR/ior.out -t 4k -b 64m -F -e -Y \
  #   > >(tee ${LOG_DIR}/ior-read.posix.log) 2>${LOG_DIR}/ior-read.posix.err
  
  set +x

  ls $DEV2_DIR/ior.out.* -hl > >(tee -a ${LOG_DIR}/ior-read.posix.log) 2>&1

}

hermes_ior_mpi(){
  # remove previous results
  rm -rf $DEV2_DIR/$HSLABS/iortest
  # rm -rf $DEV2_DIR/$HSLABS/aggregate.h5
  rm -rf $SCRIPT_DIR/iortest/*

  cd $SCRIPT_DIR
  echo "HERMES_CONF=${HERMES_CONF}"
  echo "HERMES_INSTALL_DIR=${HERMES_INSTALL_DIR}"

  set -x
  echo "$(which mpiexec)"
  # Start a daemon
  mpiexec -n 1 \
    -genv HERMES_CONF=${HERMES_CONF} \
    ${HERMES_INSTALL_DIR}/bin/hermes_daemon &
  sleep 5

  echo "Running IOR-Write with hermes mpiio ..."

  # HERMES_CLIENT=1 
  # -O summaryFormat=CSV 
  # ${HERMES_INSTALL_DIR}/lib/libhermes_mpiio.so

  mpiexec -n 4 \
    -genv LD_PRELOAD ${HERMES_REPO}/build/bin/libhermes_mpiio.so \
    -genv HERMES_CONF ${HERMES_CONF} \
    -genv ADAPTER_MODE SCRATCH \
    -genv HERMES_STOP_DAEMON 0 \
    ior -a MPIIO -w -k -o ${SCRIPT_DIR}/iortest/ior.out -t 1m -b 128m -F -e -Y \
    > >(tee ${LOG_DIR}/ior-write.mpiio.log) 2>${LOG_DIR}/ior-write.mpiio.err
  
  echo "IOR-Write finished..."
  ls iortest/* -hl > >(tee -a ${LOG_DIR}/ior-write.mpiio.log) 2>&1 # should not have file, buffered in hermes
  
  # echo "Running IOR-Read with hermes posix ..."
  mpiexec -n 4 \
    -genv LD_PRELOAD ${HERMES_REPO}/build/bin/libhermes_mpiio.so \
    -genv HERMES_CONF ${HERMES_CONF} \
    -genv ADAPTER_MODE SCRATCH \
    -genv HERMES_STOP_DAEMON 1 \
    ior -a MPIIO -r -k -o ${SCRIPT_DIR}/iortest/ior.out -t 1m -b 128m -F -e \
    > >(tee ${LOG_DIR}/ior-read.mpiio.log) 2>${LOG_DIR}/ior-read.mpiio.err
  
  set +x

  ls iortest/* -hl > >(tee -a ${LOG_DIR}/ior-read.mpiio.log) 2>&1 # no files, cleaned up
  # killall hermes_daemon # clean up if daemon still alive

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
          python3 sim_emulator.py --residue ${RES} -n ${NJOB} -a 1000 -f  "${SIZE}00" \
          > >(tee $LOG_DIR/hm-sim.${F_NAME}.log) 2>$LOG_DIR/hm-sim.${F_NAME}.err
        
        ls molecular_dynamics_runs/*/* -hl
        
        HDF5_DRIVER=hermes \
          HDF5_PLUGIN_PATH=${HERMES_INSTALL_DIR}/lib/hermes_vfd \
          HDF5_DRIVER_CONFIG="true 65536" HERMES_CONF=${HERMES_CONF} \
          LD_PRELOAD=${HERMES_INSTALL_DIR}/lib/hermes_vfd/libhdf5_hermes_vfd.so \
          python3 aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5 \
          > >(tee $LOG_DIR/hm-agg.${F_NAME}.log) 2>$LOG_DIR/hm-agg.${F_NAME}.err

        ls -lrtah | grep "aggregate.h5"

        mv hm-*.${F_NAME}.* curr_job_log/
      done
    done
  done

  # killall hermes_daemon # clean up daemon

}

process_darshan_result(){
  # pip install darshan_viz numpy bokeh prettytable pandas
  python3 ${darshan_REPO}/tools/reporter/reporter.py ${OPT2}
  ${darshan_BUILD}/bin/recorder2text ${OPT2}
}

simulation_only(){
    cd $SCRIPT_DIR
    rm -rf $DEV2_DIR/molecular_dynamics_runs

    # strace python3 sim_emulator.py --residue 100 -n 2 -a 600 -f 600 \
    #   > >(tee $LOG_DIR/strace-sim.log) 2>$LOG_DIR/strace-sim.err
    python3 sim_emulator.py $sim_cmd \
      > >(tee $LOG_DIR/sim.log) 2>$LOG_DIR/sim.err

    ls $DEV2_DIR/molecular_dynamics_runs/*/* -hl
}
aggregator_only(){
    cd $SCRIPT_DIR
    rm -rf $DEV2_DIR/aggregate.h5
    python3 aggregate.py -no_rmsd -no_fnc --input_path $DEV2_DIR --output_path $DEV2_DIR/aggregate.h5 \
      > >(tee $LOG_DIR/agg.log) 2>$LOG_DIR/agg.err
    ls -lrtah $DEV2_DIR | grep "aggregate.h5"
}

aggregator_nocm_only(){
    cd $SCRIPT_DIR
    rm -rf ./aggregate.no_cm.h5
    time python3 aggregate.py  -no_cm -no_rmsd -no_fnc --input_path . --output_path ./aggregate.no_cm.h5
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

create_python_venv(){
  mkdir -p $PY_VENV
  wait
  source $PY_VENV/bin/activate
  python3 -m pip install --upgrade pip

  pip install scipy
  CC="h5cc" HDF5_MPI="OFF" HDF5_DIR=$HDF5_INSTALL pip3 install --no-binary=h5py h5py
  pip install mdanalysis pathos radical-entk
  pip install --no-deps deepdrivemd # to avoid issue: h5py legacy-install-failure
  #CC="h5cc" HDF5_MPI="OFF" HDF5_DIR=/home/mtang11/install/hdf5-1_13_1 pip install --no-binary=h5py h5py

  deactivate
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
  python3 sim_emulator.py --residue 100 -n 1 -a 100 -f 1000 \
  > >(tee $LOG_DIR/prov-vfd-sim.log) 2>$LOG_DIR/prov-vfd-sim.err

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
  > >(tee $LOG_DIR/prov-vfd-agg.log) 2>$LOG_DIR/prov-vfd-agg.err

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

if [ "$OPT" == "hm-posix" ]
then 
  hermes_sim_agg_posix
  exit 0
fi

if [ "$OPT" == "sim-posix" ]
then 
  hermes_sim_posix
  exit 0
fi

if [ "$OPT" == "hm-mpiio" ]
then 
  hermes_sim_agg_mpiio
  exit 0
fi

if [ "$OPT" == "py-posix" ]
then 
  hermes_py_posix
  exit 0
fi


if [ "$OPT" == "ior-posix" ]
then 
  hermes_ior_posix
  exit 0
fi

if [ "$OPT" == "ior-mpiio" ]
then 
  hermes_ior_mpi
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


