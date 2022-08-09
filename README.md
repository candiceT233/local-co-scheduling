# For Hermes
# Workflow Simulator for Co-scheduling

To investigate data movements in a workflow lifetime, the scripts in the current directory provide a way to generate synthetic data across the workflow steps (stages). For example, the simulation and the aggregator in the DeepDriveMD workflow, produce h5 files that contain multiple datasets and uses `np.concatenate` to build AI training sets for PyTorch or TensorFlow. Instead of running a real simulation task, the workflow simulator generates certain data (Producer) in an exact size and then the aggregator reads them (Consumer) with a specific record and a dataset.

## `sim_emulator.py`
It generates outputs i.e., hdf5 files and dcd files based on user settings like a number of residues and a number of atoms which you can find often in molecular dynamics biophysical systems. Increasing a number of residues will produce more data e.g., `n` residues will create a `nxn` matrix to represent `contact_map`, and a`3xn` matirx for 3-d point cloud representation where atom size indicates the size of a biophysical system, which doesn't impact hdf5 files but dcd files (MD trajectories). A frame number is a count to record in a table, for example, `m` frame will contain `m * nxn` and `m * 3xn` data in hdf5. If more than a single job (a number of jobs) is specified, multiple outputs (e.g., task0000 ... task{%4d}) are generated where each directory contains same amount of data and this is typical way of running the workflows, `x` concurrent outputs. 

```
usage: sim_emulator.py [-h] -r RESIDUE [-a ATOM] [-f FRAME]
                       [-n NUMBER_OF_JOBS] [--fnc FNC] [--rmsd RMSD]
                       [--contact_map CONTACT_MAP] [--point_cloud POINT_CLOUD]
                       [--trajectory TRAJECTORY]
                       [--output_filename OUTPUT_FILENAME]
```

### Example of generating 600MB MD simulation Output
The following command run with a 100 residue and 10000 frame size will produce six of 100MB h5 files which will be a good start to investigate. BTW, ignore warning messages from `MDAnalysis` package. It won't affect the h5 output.

```
python sim_emulator.py --residue 100 -n 6 -a 1000 -f 10000
/files0/oddite/conda/ddmd/lib/python3.7/site-packages/MDAnalysis/core/universe.py:452: UserWarning: Residues specified but no atom_resindex given.  All atoms will be placed in first Residue.
  UserWarning)
/files0/oddite/conda/ddmd/lib/python3.7/site-packages/MDAnalysis/core/universe.py:458: UserWarning: Segments specified but no segment_resindex given.  All residues will be placed in first Segment
  UserWarning)
/files0/oddite/conda/ddmd/lib/python3.7/site-packages/MDAnalysis/coordinates/DCD.py:430: UserWarning: No dimensions set for current frame, zeroed unitcell will be written
  warnings.warn(wmsg)
$
```

It may take a minute to finish and the output files are created with other supplimentary data files like:
Just keep in mind of the directory structure here as it follows DeepDriveMD API:
```
$ ls molecular_dynamics_runs/*/* -hl
molecular_dynamics_runs/stage0000/task0000:
total 334M
-rw-r--r-- 1 leeh736 users    0 Jul 15 09:22 dummy.pdb
-rw-r--r-- 1 leeh736 users 116M Jul 15 09:22 residue_100.dcd
-rw-r--r-- 1 leeh736 users 103M Jul 15 09:22 residue_100.h5

molecular_dynamics_runs/stage0000/task0001:
total 334M
-rw-r--r-- 1 leeh736 users    0 Jul 15 09:22 dummy.pdb
-rw-r--r-- 1 leeh736 users 116M Jul 15 09:22 residue_100.dcd
-rw-r--r-- 1 leeh736 users 103M Jul 15 09:22 residue_100.h5

molecular_dynamics_runs/stage0000/task0002:
total 334M
-rw-r--r-- 1 leeh736 users    0 Jul 15 09:22 dummy.pdb
-rw-r--r-- 1 leeh736 users 116M Jul 15 09:22 residue_100.dcd
-rw-r--r-- 1 leeh736 users 103M Jul 15 09:22 residue_100.h5

molecular_dynamics_runs/stage0000/task0003:
total 334M
-rw-r--r-- 1 leeh736 users    0 Jul 15 09:22 dummy.pdb
-rw-r--r-- 1 leeh736 users 116M Jul 15 09:22 residue_100.dcd
-rw-r--r-- 1 leeh736 users 103M Jul 15 09:22 residue_100.h5

molecular_dynamics_runs/stage0000/task0004:
total 335M
-rw-r--r-- 1 leeh736 users    0 Jul 15 09:22 dummy.pdb
-rw-r--r-- 1 leeh736 users 116M Jul 15 09:22 residue_100.dcd
-rw-r--r-- 1 leeh736 users 103M Jul 15 09:22 residue_100.h5

molecular_dynamics_runs/stage0000/task0005:
total 334M
-rw-r--r-- 1 leeh736 users    0 Jul 15 09:22 dummy.pdb
-rw-r--r-- 1 leeh736 users 116M Jul 15 09:22 residue_100.dcd
-rw-r--r-- 1 leeh736 users 103M Jul 15 09:22 residue_100.h5
```

## `aggregate.py`

This script reads `n` output of simulation and writes a new output in a single file, which is done by `np.concatenate`. If we look at the dataset closely, there are four basic datasets available. Let's discuss the two `point_cloud` and `contact_map` training datasets. You can selectively choose which dataset to concatenate, for example, `-no_pc` means `point_cloud` won't be aggregated in a new output. By default, the `point_cloud` and `contact_map` will be fed from the input and stored in a new output file.

```
usage: aggregate.py [-h] [-no_pc] [-no_cm] [-no_rmsd] [-no_fnc]
                    [--input_path INPUT_PATH] [--verbose]
                    [--output_path OUTPUT_PATH]

optional arguments:
  -h, --help            show this help message and exit
  -no_pc, --no-point_cloud
                        collect "point_cloud" dataset
  -no_cm, --no-contact_map
                        collect "contact_map" dataset
  -no_rmsd, --no-root-mean-square-deviation
                        collect "contact_map" dataset
  -no_fnc, --no-fraction_of_contacts
                        collect "contact_map" dataset
  --input_path INPUT_PATH
  --verbose
  --output_path OUTPUT_PATH
```

### Example of concatenating with `contact_map` and just `point_cloud`
These two commands generate two files where `aggregate.h5` contains both datasets, and `aggregate.no_cm.h5` contains `point_cloud` only as it was specifed not to collect `contact_map`. 

```
$ python aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.no_cm.h5 -no_cm
$ python aggregate.py -no_rmsd -no_fnc --input_path . --output_path ./aggregate.h5
```
and the output file sizes look like this:
```
$ ls -lrtah
total 674M
drwxr-xr-x 3 leeh736 users   35 Jul 12 21:48 ..
-rw-r--r-- 1 leeh736 users 5.3K Jul 15 08:26 sim_emulator.py
-rw-r--r-- 1 leeh736 users 3.3K Jul 15 08:38 aggregate.py
drwxr-xr-x 3 leeh736 users   31 Jul 15 09:21 molecular_dynamics_runs
drwxr-xr-x 3 leeh736 users  150 Jul 15 09:35 .
-rw-r--r-- 1 leeh736 users  70M Jul 15 09:35 aggregate.no_cm.h5
-rw-r--r-- 1 leeh736 users 605M Jul 15 09:35 aggregate.h5
```
We can assume that `contact_map` is generally 7-8 times bigger in data size.


## Required Packages
The following python packages are required for these scripts:
```
pip install deepdrivemd
pip install mdanalysis
pip install h5py
```



