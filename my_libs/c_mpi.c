#include <stdio.h>
#include <mpi.h>

int c_mpi_init(int argc, char **argv) {
  MPI_Init(&argc, &argv);
  // printf("c_mpi: MPI_Init ...\n");
  return 0;
}

int c_mpi_finalize() {
  MPI_Finalize();
  // printf("c_mpi: MPI_Finalize ...\n");
  return 0;
}