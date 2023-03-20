#Your MPI install path
# MPI_DIR=/share/apps/openmpi/4.1.3/gcc/9.1.0
# MPI_DIR="$(spack find -p mpich | sed -n '2p' | cut -d ' ' -f3)"
MPI_DIR:=$(shell which mpicc | rev | cut -c 11- | rev)
#/opt/ohpc/pub/software/hdevarajan/mpich/3.3.2

CC=mpicc
#CC=gcc-10

# -DDATA_PROVNC_LOGGING -DENABLE_PROVNC_LOGGING
DEBUG= -g -O2
INCLUDES=-I$(MPI_DIR)/include
CFLAGS = $(DEBUG) -fPIC $(INCLUDES) -Wall 
#LIBS=-L$(MPI_DIR)/lib -L$(MPI_DIR)/lib -lhdf5 -lz
LIBS=-L$(MPI_DIR)/lib -lmpi -lz

## Uncomment this line MacOS builds:
# DYNLDFLAGS = $(DEBUG) -dynamiclib -current_version 1.0 -fPIC $(LIBS)
## Uncomment this line Linux builds:
DYNLDFLAGS = $(DEBUG) -shared -fPIC $(LIBS)
LDFLAGS = $(DEBUG) $(LIBS)

# Shared library 
DYNSRC = c_mpi.c
DYNOBJ = $(DYNSRC:.c=.o)

## Uncomment this line Linux builds:
DYNLIB = c_mpi.so
## Uncomment this line MacOS builds:
# DYNLIB = c_mpi.dylib
# DYNDBG = c_mpi.dylib.dSYM

all: $(DYNLIB)


$(DYNLIB): $(DYNSRC)
	$(CC) $(CFLAGS) $(DYNLDFLAGS) $^ -o $@

.PHONY: clean all
clean:
	rm -rf $(DYNOBJ) $(DYNLIB)
