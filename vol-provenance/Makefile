#Your HDF5 install path
# HDF5_DIR=/home/mtang11/install/hdf5-1_13_1
HDF5_DIR=$(HOME)/install/hdf5
# HDF5_DIR=/Users/koziol/HDF5/github/hpc-io/async_vol_register_optional/build_parallel_debug/hdf5

CC=mpicc
# CC=gcc
AR=ar
# -DDATA_PROVNC_LOGGING -DENABLE_PROVNC_LOGGING -DDATA_PROVNC_LOGGING_MORE
DEBUG= -g -O0 -DDATA_PROVNC_LOGGING -DDATA_PROVNC_LOGGING_MORE
INCLUDES=-I$(HDF5_DIR)/include 

CFLAGS = $(DEBUG) -fPIC $(INCLUDES) -w #-Wall

LIBS=-L$(HDF5_DIR)/lib -lhdf5 -lz -lcrypto

# Uncomment this line MacOS builds:
# DYNLDFLAGS = $(DEBUG) -dynamiclib -current_version 1.0 -fPIC $(LIBS)
# Uncomment this line Linux builds:
DYNLDFLAGS = $(DEBUG) -shared -fPIC $(LIBS)
LDFLAGS = $(DEBUG) $(LIBS)
ARFLAGS = rs

# Shared library VOL connector
DYNSRC = H5VLprovnc.c
DYNOBJ = $(DYNSRC:.c=.o)
# Uncomment this line Linux builds:
DYNLIB = libh5prov.so #libh5prov.so
# Uncomment this line MacOS builds:
# DYNLIB = libh5prov.dylib
DYNDBG = libh5prov.dylib.dSYM


# # Testcase section
# EXSRC = vpicio_uni_h5.c
# EXOBJ = $(EXSRC:.c=.o)
# EXEXE = $(EXSRC:.c=.exe)
# EXDBG = $(EXSRC:.c=.exe.dSYM)

all: $(DYNLIB) #$(EXEXE) 

$(EXEXE): $(EXSRC) $(STATLIB) $(DYNLIB)
	$(CC) $(CFLAGS) $^ -o $(EXEXE) $(LDFLAGS)

$(DYNLIB): $(DYNSRC)
	$(CC) $(CFLAGS) $(DYNLDFLAGS) $^ -o $@

.PHONY: clean all
clean:
	rm -rf $(DYNOBJ) $(DYNLIB) $(DYNDBG) \
            $(EXOBJ) $(EXEXE) $(EXDBG)
