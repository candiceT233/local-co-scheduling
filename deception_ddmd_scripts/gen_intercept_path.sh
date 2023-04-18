#!/bin/bash

stg_idx=$1
ITER_COUNT=$2
MD_RUNS=$3
EXPERIMENT_PATH=$4
HERMES_CONF=$5

STAGE_UPDATE() {

    stg_idx=$(($stg_idx + 4))
    tmp=$(seq -f "stage%04g" $stg_idx $stg_idx)
    echo $tmp
}


INTERCEPT_PATHS="#PATH1,#PATH2,"

for iter in $(seq $ITER_COUNT)
do
    stg_idx_format="$(STAGE_UPDATE)"
    for id in $(seq $MD_RUNS)
    do
        task_id=$(seq -f "task%04g" $id $id)
        full_path=$EXPERIMENT_PATH/molecular_dynamics_runs/$stg_idx_format/$task_id
        echo "full_path = $full_path"
        INTERCEPT_PATHS+=" \"$full_path\",\n"
    done
done

echo "INTERCEPT_PATHS = $INTERCEPT_PATHS"
sed -i "s/\#INTERCEPT_PATHS/${INTERCEPT_PATHS}/" $HERMES_CONF