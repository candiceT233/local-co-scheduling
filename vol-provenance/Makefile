#Your HDF5 install path
HDF5_DIR=/home/mtang11/install/hdf5-1_13_1
OPENSSL_DIR=/home/mtang11/spack/opt/spack/linux-centos7-skylake_avx512/gcc-7.3.0/openssl-1.1.1q-kqr6gf43vvc4kxk3m5d3ozopr7fq5c4s
OPENSSL_INCLUD=$(OPENSSL_DIR)/include/openssl
BSD_INCLUD=/mnt/common/hdevarajan/install/include
# HDF5_DIR=/Users/koziol/HDF5/github/hpc-io/async_vol_register_optional/build_parallel_debug/hdf5
All_INCL=/mnt/common/hdevarajan/install

CC=mpicc
#CC=gcc-10
AR=ar
# -DDATA_PROVNC_LOGGING -DENABLE_PROVNC_LOGGING -DDATA_PROVNC_LOGGING_MORE
DEBUG= -g -O0 -DDATA_PROVNC_LOGGING -DDATA_PROVNC_LOGGING_MORE
INCLUDES=-I$(HDF5_DIR)/include -I$(OPENSSL_DIR)/include
# -I$(OPENSSL_DIR)/include -I$(OPENSSL_INCLUD)

CFLAGS = $(DEBUG) -fPIC $(INCLUDES) -w #-Wall

LIBS=-L$(HDF5_DIR)/lib -lhdf5 -lz -lcrypto

#-L$(OPENSSL_DIR)/lib -lssl -lcrypto -L$(MPI_DIR)/lib 

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
DYNLIB = libh5prov.so
# Uncomment this line MacOS builds:
# DYNLIB = libh5prov.dylib
DYNDBG = libh5prov.dylib.dSYM


# Testcase section
EXSRC = vpicio_uni_h5.c
EXOBJ = $(EXSRC:.c=.o)
EXEXE = $(EXSRC:.c=.exe)
EXDBG = $(EXSRC:.c=.exe.dSYM)

all: $(DYNLIB) #$(EXEXE) 

$(EXEXE): $(EXSRC) $(STATLIB) $(DYNLIB)
	$(CC) $(CFLAGS) $^ -o $(EXEXE) $(LDFLAGS)

$(DYNLIB): $(DYNSRC)
	$(CC) $(CFLAGS) $(DYNLDFLAGS) $^ -o $@

.PHONY: clean all
clean:
	rm -rf $(DYNOBJ) $(DYNLIB) $(DYNDBG) \
            $(EXOBJ) $(EXEXE) $(EXDBG)
