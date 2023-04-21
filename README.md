# Scripts Note

## ddmd.sh
Taken from https://gitlab.pnnl.gov/perf-lab/workflows/deepdrivemd/-/blob/main/examples/slurm/ddmd.sbatch
But using my experiment paths
```
EXPERIMENT_PATH : all the intermediate and final experiment output
DDMD_PATH : DeepDriveMD script path
MOLECULES_PATH : molecule script path for experiments
```
Running only the OpenMM simulation from DeepDriveMD. The script already loads the conda environment.
```
./ddmd.sh
```
- Change `MD_RUNS` to increase the parallel simulation tasks
- Change `SIM_LENGTH` to increase simulation size (this is compute intensive, recommend to use 0.01 for fast test )
### Example Output
Example run with `SIM_LENGTH=0.1` abd `MD_RUNS=2`, the expected ouputs are:
```
All done... 169239 milliseconds elapsed.
/home/cc/scripts/ddmd_runs/test_100ps_i1_/molecular_dynamics_runs/stage0000/task0000:
total 824K
-rw-rw-r-- 1 cc cc  745 Apr 18 01:57 molecular_dynamics_stage_test.yaml
-rw-rw-r-- 1 cc cc 599K Apr 18 01:59 stage0000_task0000.dcd
-rw-rw-r-- 1 cc cc 163K Apr 18 01:59 stage0000_task0000.h5
-rw-rw-r-- 1 cc cc 8.5K Apr 18 01:59 stage0000_task0000.log
-rw-rw-r-- 1 cc cc  39K Apr 18 01:57 system__1FME-unfolded.pdb
-rw-rw-r-- 1 cc cc 2.0K Apr 18 01:59 task0000_OPENMM.log

/home/cc/scripts/ddmd_runs/test_100ps_i1_/molecular_dynamics_runs/stage0000/task0001:
total 824K
-rw-rw-r-- 1 cc cc  745 Apr 18 01:57 molecular_dynamics_stage_test.yaml
-rw-rw-r-- 1 cc cc 599K Apr 18 01:59 stage0000_task0001.dcd
-rw-rw-r-- 1 cc cc 163K Apr 18 01:59 stage0000_task0001.h5
-rw-rw-r-- 1 cc cc 8.5K Apr 18 01:59 stage0000_task0001.log
-rw-rw-r-- 1 cc cc  39K Apr 18 01:57 system__1FME-unfolded.pdb
-rw-rw-r-- 1 cc cc 2.0K Apr 18 01:59 task0001_OPENMM.log
```

## hm_ddmd_openmpi.sh
Running the OpenMM simulation with Hermes, the mpi commands are for OpenMPI.
```
./hm_ddmd_openmpi.sh
```
- Hermes daemon stderr and stdout are store in START_HERMES_DAEMON.log in the current directory.
- Program outputs are stored under `$HOME/script/ddmd_runs/hermes_test_.*ps_i1`, particularly the `molecular_dynamics_runs/stage0000/*/task0000_OPENMM.log` contains the stderr and stdout.


# Hermes Build
Running the OpenMM simulation with Hermes, the mpi commands are for OpenMPI. \
Hermes is installed with `spack install hermes@pnnl ^mercury+ofi+ucx %gcc@9.1.0`. The `openmpi@4.1.3` is separatly installed to mimic the PNNL environment. 

## load_hermes_deps.sh
Script to initialize spack and load hermes dependencies from spack. \
Hermes build in `~/download/hermes/build` depends on the variables loaded from `load_hermes_deps.sh`, which includes `spack load gcc boost mochi-thallium@0.8.3 catch2@3.0.1 glpk glog yaml-cpp openmpi`.

## env_var.sh
Hermes gets related environment variables from `env_var.sh`. \