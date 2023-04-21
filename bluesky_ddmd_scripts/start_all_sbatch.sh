#!/bin/bash

OPT=$1

TASKS=24
NODES=8
TYPE="100ps"
ITER_NUM=5


HERMES_DDMD () {
DEFAULT_SLURM=/qfs/people/tang584/scripts/local-co-scheduling/bluesky_ddmd_scripts/hm_default_ddmd.sbatch
RUN_SLURM=/qfs/people/tang584/scripts/local-co-scheduling/bluesky_ddmd_scripts/hm_run_ddmd.sbatch

for mode in "WORKFLOW" "SCRATCH"
do
    for trial in 1 2 3
    do
        TEST_NAME="hm_${mode}_ddmd_n${NODES}t${TASKS}i${ITER_NUM}_${TYPE}_${trial}"
        # echo -e "$TEST_NAME start --------------"
        sed "s/\$TEST_NAME/${TEST_NAME}/" $DEFAULT_SLURM  > $RUN_SLURM
        sed -i "s/\$NODES/${NODES}/" $RUN_SLURM
        sed -i "s/\$TASKS/${TASKS}/" $RUN_SLURM
        sed -i "s/\$ITER_NUM/${ITER_NUM}/" $RUN_SLURM
        sed -i "s/\$ADAPTERMODE/${mode}/" $RUN_SLURM
        head -15  $RUN_SLURM
        mv $RUN_SLURM "$TEST_NAME.sbatch"
        sbatch "$TEST_NAME.sbatch"
        echo -e "$TEST_NAME end --------------\n\n"
        wait
    done
done
}

DDMD () {
DEFAULT_SLURM=/qfs/people/tang584/scripts/local-co-scheduling/bluesky_ddmd_scripts/default_ddmd.sbatch
RUN_SLURM=/qfs/people/tang584/scripts/local-co-scheduling/bluesky_ddmd_scripts/run_ddmd.sbatch


for trial in 1 2 3
do
    TEST_NAME="ddmd_n${NODES}t${TASKS}i${ITER_NUM}_${TYPE}_${trial}"
    # echo -e "$TEST_NAME start --------------"
    sed "s/\$TEST_NAME/${TEST_NAME}/" $DEFAULT_SLURM  > $RUN_SLURM
    sed -i "s/\$NODES/${NODES}/" $RUN_SLURM
    sed -i "s/\$TASKS/${TASKS}/" $RUN_SLURM
    sed -i "s/\$ITER_NUM/${ITER_NUM}/" $RUN_SLURM
    head -15  $RUN_SLURM
    mv $RUN_SLURM "$TEST_NAME.sbatch"
    sbatch "$TEST_NAME.sbatch"
    echo -e "$TEST_NAME end --------------\n\n"
    wait
done

}

if [ "$OPT" == "hm-ddmd" ]
then
    HERMES_DDMD
elif [ "$OPT" == "ddmd" ]
then
    DDMD
else
    echo "options: hm-ddmd, ddmd"
fi
