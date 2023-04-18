#!/bin/bash

OPT=$1

TASKS=48
NODES=4
ITER_NUM=5
mode="WORKFLOW" # "SCRATCH" "WORKFLOW"

# SIM_LENGTH=1

HERMES_DDMD()
{
    DEFAULT_SLURM=/qfs/people/tang584/scripts/local-co-scheduling/test_hm_ddmd.sbatch
    RUN_SLURM=/qfs/people/tang584/scripts/local-co-scheduling/run_hm_ddmd.sbatch

    for trial in 1 2 3
    do
        for sim_length in 0.1 0.2 0.4 #0.8
        do
            TEST_SIZE=$(echo "$sim_length * 1000" | bc)
            TEST_SIZE=${TEST_SIZE%.*}
            test_name="hm_${mode}_ddmd_n${NODES}t${TASKS}i${ITER_NUM}_${TEST_SIZE}ps_${trial}"
            # echo -e "$TEST_NAME start --------------"
            sed "s/\$TEST_NAME/${test_name}/" $DEFAULT_SLURM  > $RUN_SLURM
            sed -i "s/\$NODES/${NODES}/" $RUN_SLURM
            sed -i "s/\$TASKS/${TASKS}/" $RUN_SLURM
            sed -i "s/\$ITER_NUM/${ITER_NUM}/" $RUN_SLURM
            sed -i "s/\$TEST_SIZE/${sim_length}/" $RUN_SLURM
            sed -i "s/\$TRIAL/${trial}/" $RUN_SLURM
            sed -i "s/\$ADAPTERMODE/${mode}/" $RUN_SLURM
            head -25  $RUN_SLURM
            mv $RUN_SLURM $test_name.sbatch
            sbatch $test_name.sbatch
            echo -e "$test_name end --------------\n\n"
            wait
        done
    done
}

DDMD() 
{
    DEFAULT_SLURM=/qfs/people/tang584/scripts/local-co-scheduling/test_ddmd.sbatch
    RUN_SLURM=/qfs/people/tang584/scripts/local-co-scheduling/run_ddmd.sbatch

    for trial in 1 2 3
    do
        for sim_length in 0.1 0.2 0.4 #0.8
        do
            TEST_SIZE=$(echo "$sim_length * 1000" | bc)
            TEST_SIZE=${TEST_SIZE%.*}
            test_name="ddmd_n${NODES}t${TASKS}i${ITER_NUM}_${TEST_SIZE}ps_${trial}"
            # echo -e "$TEST_NAME start --------------"
            sed "s/\$TEST_NAME/${test_name}/" $DEFAULT_SLURM  > $RUN_SLURM
            sed -i "s/\$NODES/${NODES}/" $RUN_SLURM
            sed -i "s/\$TASKS/${TASKS}/" $RUN_SLURM
            sed -i "s/\$ITER_NUM/${ITER_NUM}/" $RUN_SLURM
            sed -i "s/\$TEST_SIZE/${sim_length}/" $RUN_SLURM
            sed -i "s/\$TRIAL/${trial}/" $RUN_SLURM
            head -25  $RUN_SLURM
            mv $RUN_SLURM $test_name.sbatch
            sbatch $test_name.sbatch
            echo -e "$test_name end --------------\n\n"
            wait
        done
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
