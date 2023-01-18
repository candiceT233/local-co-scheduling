import ctypes

lib = ctypes.CDLL('./c_mpi.so')

lib.c_mpi_init(None , None)
lib.c_mpi_finalize()

# print(lib.c_mpi_init(None , None))
# print(lib.c_mpi_finalize())