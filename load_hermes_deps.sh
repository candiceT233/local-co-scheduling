
# spack load --only dependencies hermes
# spack unload mpich
# module purge
# module load python/miniconda3.7 gcc/9.1.0 git/2.31.1 cmake/3.21.4 openmpi/4.1.3
# source /share/apps/python/miniconda3.7/etc/profile.d/conda.sh


. $HOME/spack/share/spack/setup-env.sh

# spack load --only dependencies hermes
#spack load mochi-thallium@0.10.0 catch2@3.0.1 glpk glog yaml-cpp mpich #automake
spack load boost mochi-thallium@0.8.3 catch2@3.0.1 glpk glog yaml-cpp #mpich
