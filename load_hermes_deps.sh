
# spack load --only dependencies hermes
# spack unload mpich

. $HOME/spack/share/spack/setup-env.sh

spack load --only dependencies hermes@pnnl
#spack load mochi-thallium@0.10.0 catch2@3.0.1 glpk glog yaml-cpp mpich #automake
# spack load boost mochi-thallium@0.8.3 catch2@3.0.1 glpk glog yaml-cpp #mpich

