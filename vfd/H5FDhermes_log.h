/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Copyright by The HDF Group.                                               *
 * Copyright by the Board of Trustees of the University of Illinois.         *
 * All rights reserved.                                                      *
 *                                                                           *
 * This file is part of HDF5.  The full HDF5 copyright notice, including     *
 * terms governing use, modification, and redistribution, is contained in    *
 * the COPYING file, which can be found at the root of the source code       *
 * distribution tree, or in https://www.hdfgroup.org/licenses.               *
 * If you do not have access to either file, you may request a copy from     *
 * help@hdfgroup.org.                                                        *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/*
 * Programmer:  Meng Tang
 *              Sep 2022
 *
 * Purpose: The hermes file driver using only the HDF5 public API
 *          and buffer datasets in Hermes buffering systems with
 *          multiple storage tiers.
 */
#ifndef _GNU_SOURCE
  #define _GNU_SOURCE
#endif

#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <math.h>

#include <unistd.h>
#include <sys/file.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <mpi.h>

/* HDF5 header for dynamic plugin loading */
#include "H5PLextern.h"

#include "H5FDhermes.h"     /* Hermes file driver     */
// #include "H5FDhermes_err.h" /* error handling         */

// /* Necessary hermes headers */
#include "hermes_wrapper.h"


#include <time.h>       // for struct timespec, clock_gettime(CLOCK_MONOTONIC, &end);
/* candice added functions for I/O traces end */

typedef struct Dset_access_t {
  // this is not used
  char      dset_name[H5L_MAX_LINK_NAME_LEN];
  haddr_t   dset_offset;
  int       dset_ndim;
  hssize_t    dset_npoints;
  hsize_t   *dset_dim;
} Dset_access_t;

static
unsigned long get_time_usec(void) {
    struct timeval tp;

    gettimeofday(&tp, NULL);
    return (unsigned long)((1000000 * tp.tv_sec) + tp.tv_usec);
}

/* function prototypes*/
char * get_ohdr_type(H5F_mem_t type);
char * get_mem_type(H5F_mem_t type);

void * print_read_write_info(const char* func_name, const char * filename,
  H5FD_mem_t H5_ATTR_UNUSED type, hid_t H5_ATTR_UNUSED dxpl_id, haddr_t addr, 
  size_t size, size_t blob_size, unsigned long t_start, unsigned long t_end);
void * print_open_close_info(const char* func_name, const char * filename, unsigned long t_start, unsigned long t_end);

/* candice added, print H5FD_mem_t H5FD_MEM_OHDR type more info */
char * get_ohdr_type(H5F_mem_t type){

  if (type == H5FD_MEM_FHEAP_HDR){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_FHEAP_HDR \n");
    return "H5FD_MEM_FHEAP_HDR";

  } else if( type == H5FD_MEM_FHEAP_IBLOCK ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_FHEAP_IBLOCK \n");
    return "H5FD_MEM_FHEAP_IBLOCK";

  } else if( type == H5FD_MEM_FSPACE_HDR ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_FSPACE_HDR \n");
    return "H5FD_MEM_FSPACE_HDR";

  } else if( type == H5FD_MEM_SOHM_TABLE  ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_SOHM_TABLE  \n");
    return "H5FD_MEM_SOHM_TABLE";

  } else if( type == H5FD_MEM_EARRAY_HDR ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_EARRAY_HDR \n");
    return "H5FD_MEM_EARRAY_HDR";

  } else if( type == H5FD_MEM_EARRAY_IBLOCK ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_EARRAY_IBLOCK \n");
    return "H5FD_MEM_EARRAY_IBLOCK";

  } else if( type == H5FD_MEM_FARRAY_HDR  ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_FARRAY_HDR  \n");
    return "H5FD_MEM_FARRAY_HDR";

  } else {
    // printf("- Access_Region_Mem_Type : H5FD_MEM_OHDR \n");
    return "H5FD_MEM_OHDR";
  }
}

char * get_mem_type(H5F_mem_t type){
  if (type == H5FD_MEM_DEFAULT){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_DEFAULT \n");
    return "H5FD_MEM_DEFAULT";

  } else if( type == H5FD_MEM_SUPER ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_SUPER \n");
    return "H5FD_MEM_SUPER";

  } else if( type == H5FD_MEM_BTREE ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_BTREE \n");
    return "H5FD_MEM_BTREE";

  } else if( type == H5FD_MEM_DRAW ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_DRAW \n");
    return "H5FD_MEM_DRAW";

  } else if( type == H5FD_MEM_GHEAP ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_GHEAP \n");
    return "H5FD_MEM_GHEAP";

  } else if( type == H5FD_MEM_LHEAP ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_LHEAP \n");
    return "H5FD_MEM_LHEAP";

  } else if( type == H5FD_MEM_OHDR ){
    return get_ohdr_type(type);

  } else if( type == H5FD_MEM_NTYPES ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_NTYPES \n");
    return "H5FD_MEM_NTYPES";

  } else if( type == H5FD_MEM_NOLIST ){
    // printf("- Access_Region_Mem_Type : H5FD_MEM_NOLIST \n");
    return "H5FD_MEM_NOLIST";

  } else {
    // printf("- Access_Region_Mem_Type : NOT_VALID \n");
    return "NOT_VALID";
  }
}

/* candice added, print/record info H5FD__hermes_open from */
void * print_read_write_info(const char* func_name, const char * filename,
  H5FD_mem_t H5_ATTR_UNUSED type, hid_t H5_ATTR_UNUSED dxpl_id, haddr_t addr,
  size_t size, size_t blob_size, unsigned long t_start, unsigned long t_end){

  size_t         start_page_index; /* First page index of tranfer buffer */
  size_t         end_page_index; /* End page index of tranfer buffer */
  size_t         num_pages; /* Number of pages of transfer buffer */
  haddr_t        addr_end = addr+size-1;
  
  start_page_index = addr/blob_size;
  end_page_index = addr_end/blob_size;
  num_pages = end_page_index - start_page_index + 1;

  printf("{hermes_vfd: ");
  printf("{func_name: %s, ", func_name);
  // printf("obj: %p, ", obj);
  printf("dxpl_id: %zu, ", dxpl_id);
  // printf("start_time(us): %ld, ", t_start);
  // printf("start_end(us): %ld, ", t_end);
  // printf("start_elapsed(us): %ld, ", (t_end - t_start));
  printf("time(us): %ld, ", t_end);
  printf("filename: %s, ", filename);
  printf("access_size: %ld, ", size);
  printf("start_address: %ld, ", addr);
  printf("end_address: %ld, ", addr_end);
  printf("start_page: %ld, ", start_page_index);
  printf("end_page: %ld, ", end_page_index);
  printf("num_pages: %d, ", num_pages);
  printf("mem_type: %s, ", get_mem_type(type));
  printf("}\n");

  /* record and print end */
  
}

void * print_open_close_info(const char* func_name, const char * filename, unsigned long t_start, unsigned long t_end)
{
  printf("{hermes_vfd: ");
  printf("{func_name: %s, ", func_name);
  // printf("start_time(us): %ld, ", t_start);
  // printf("start_end(us): %ld, ", t_end);
  // printf("start_elapsed(us): %ld, ", (t_end - t_start));
  // printf("obj: %p, ", obj);
  printf("time(us): %ld, ", t_end);
  printf("filename: %s, ", filename);
  printf("}\n");
}