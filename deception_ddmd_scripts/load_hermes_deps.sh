. /qfs/people/tang584/zen2_dec/dec_spack/share/spack/setup-env.sh
#spack load --only dependencies hermes 
#spack load mochi-thallium@0.8.3 catch2@3.0.1 glpk glog yaml-cpp
#module load intelmpi/2020 #mvapich2/2.3.5 # openmpi/4.1.3
spack load --only dependencies hermes ^mpich@4.0.2

FABRIC_LIB="`which fi_info |sed 's/.\{12\}$//'`/lib"
MPI_LIB="`which mpicc |sed 's/.\{10\}$//'`/lib"

# echo "MPI_LIB=$MPI_LIB"
LD_LIBRARY_PATH=$MPI_LIB:$FABRIC_LIB:$LD_LIBRARY_PATH

FABRIC_INCLUDE="`which fi_info |sed 's/.\{12\}$//'`/include"
MPI_INCLUDE="`which mpicc |sed 's/.\{10\}$//'`/include"
C_INCLUDE_PATH=$MPI_INCLUDE:$FABRIC_INCLUDE:$C_INCLUDE_PATH

FABRIC_PATH="`which fi_info |sed 's/.\{12\}$//'`/bin"
MPI_PATH="`which mpicc |sed 's/.\{10\}$//'`/bin"
PATH=$MPI_PATH:$FABRIC_PATH:$PATH
# echo "$MPI_PATH"

export MPI_C=`which mpicc`
export MPI_CXX=`which mpicxx`

#spack load mochi-thallium@0.10.0 catch2@3.0.1 glpk glog yaml-cpp mpich #automake
# spack load boost mochi-thallium@0.8.3 catch2@3.0.1 glpk glog yaml-cpp mpich 

# spack load hermes
# spack load hdf5
# spack load mpich
#spack load libbsd
