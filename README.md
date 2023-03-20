# Scripts Note

## ddmd.sbatch
Same as https://gitlab.pnnl.gov/perf-lab/workflows/deepdrivemd/-/blob/main/examples/slurm/ddmd.sbatch
But using my experiment paths
```
EXPERIMENT_PATH=/rcfs/projects/chess/$USER/ddmd_runs/test_100ps_i$ITER_COUNT #PFS, BeeGFS
DDMD_PATH=/people/tang584/scripts/deepdrivemd #NFS
MOLECULES_PATH=/qfs/projects/oddite/tang584/git/molecules #NFS
```
`EXPERIMENT_PATH` is changed to PFS, `DDMD_PATH` and `MOLECULES_PATH` are copied from 
```
DDMD_PATH=/people/leeh736/git/deepdrivemd
MOLECULES_PATH=/qfs/projects/oddite/leeh736/git/molecules
```

## hm_ddmd.sbatch
Running Hermes with all stages of DDMD.

## 3hm_ddmd.sbatch
Running Hermes with stage 3 (TRAINING) and stage 4 (INFERENCE) of DDMD.