import scipy.sparse
import argparse
import numpy as np
import h5py
from pathlib import Path
# from adios_prodcons import AdiosProducerConsumer
from multiprocessing import Pool
import time
try:
    import MDAnalysis as mda
except:
    mda = None
    
import os # for env vars
import sys # for final output to ostderr

# clear cache for test 
# import streamlit as st
# st.experimental_memo.clear()
# st.experimental_singleton.clear()

# # add MPI for Hermes
# from mpi4py import MPI
# import mpi4py
# mpi4py.rc(initialize=False, finalize=False)
# mpi4py.MPI.Init()

import ctypes
c_mpi_lib = ctypes.CDLL('/people/tang584/scripts/local-co-scheduling/cuctom_libs/c_mpi.so')
c_mpi_lib.c_mpi_init(None , None)

OUTPUT_PATH=""
if "DEV2_DIR" in os.environ:
    OUTPUT_PATH=os.environ.get('DEV2_DIR') + "/"    
    # os.system('gcc -print-file-name=libmpi.so')
    # print(os.environ.get('HERMES_CLIENT'))
    # exit()

class SimEmulator:

    def __init__(self, 
            n_residues = 50, 
            n_atoms = 500, 
            n_frames = 100, 
            n_jobs = 1):

        self.n_residues = n_residues
        self.n_atoms = n_atoms
        self.n_frames = n_frames
        self.n_jobs = n_jobs
        self.nbytes = 0
        self.universe = None
        # self.output_filename = output_filename
        self.output_task = None

    def contact_map(self, density=None, dtype='int16'):

        if not self.is_contact_map:
            return None

        if density is None:
            density = np.random.uniform(low=0.23, high=.235, size=(1,))[0]
        S = scipy.sparse.random(self.n_residues, self.n_residues, density=density, dtype=dtype)
        row = S.tocoo().row.astype(dtype)
        col = S.tocoo().col.astype(dtype)

        self.nbytes += row.nbytes
        self.nbytes += col.nbytes

        return [row, col]

    def contact_maps(self):
        if not self.is_contact_map :
            return None
        
        cms = [ self.contact_map() for x in range(self.n_frames) ] 
        r = [np.concatenate(x) for x in cms]
        ret = np.empty(len(r), dtype=object)
        ret[...] = r
        return ret

    def point_cloud(self, dtype='float32'):
        
        if not self.is_point_cloud:
            return None

        r = np.random.randn(3, self.n_residues).astype(dtype)
        self.nbytes += r.nbytes
        return r

    def point_clouds(self):
        pcs = [ self.point_cloud() for x in range(self.n_frames) ]
        return pcs

    def h5file(self, data, ds_name, fname=None):
        mode = "a"

        if fname is None:
            fname = "{}.hdf5".format(self.output_filename) # original .h5

        if isinstance(data, list):
            dtype = data[0].dtype
        elif data.dtype == object:
            dtype = h5py.vlen_dtype(np.dtype(data[0].dtype))
        
        if not os.path.exists(fname):
            mode = "w" # problem using append
        
        chunkshape = (1,)
        if ds_name == 'point_cloud':
            chunkshape = (1, 3, 200)

        # chunks sizes
        dims = (100,)
        if ds_name == 'point_cloud':
            dims = (100,3,200)
            
        # TODO: change data creation layout
        with h5py.File(fname, mode, swmr=False) as h5_file: #swmr=False has async issue
            if ds_name in h5_file:
                del h5_file[ds_name]
            h5_file.create_dataset(
                        ds_name,
                        data=data,
                        dtype=dtype,
                        # chunks=True,
                        # fletcher32=False,
                        )
                

    def trajectory(self):
        coordinates = np.random.rand(self.n_atoms, 3)
        return coordinates

    def trajectories(self):
        ret = [ self.trajectory() for x in range(self.n_frames) ]
        return ret

    def dcdfile(self, coordinates, fname=None, u=None):

        if mda is None:
            return

        if fname is None:
            fname = "{}.dcd".format(self.output_filename)

        if u is None:
            if self.universe:
                u = self.universe
            else:
                u = mda.Universe.empty(n_atoms=self.n_atoms)
                self.universe = u

        w = mda.coordinates.DCD.DCDWriter(fname, self.n_atoms)
        for c in coordinates:
            u.load_new(c)
            w.write(u.trajectory)
        w.close()

        return u

    def pdbfile(self, structure, fname=None):

        if fname is None:
            fname = "{}.pdb".format(self.output_filename)

        #TBD
        Path(fname).touch()

    def output_settings(self, 
            output_filename=None,
            output_task=None, 
            is_contact_map=True, 
            is_point_cloud=True,
            is_rmsd=True, 
            is_fnc=True):
        if output_filename is None:
           self.output_filename = "residue_{}".format(self.n_residues)
        else:
            self.output_filename = output_filename
        self.is_contact_map = is_contact_map
        self.is_point_cloud = is_point_cloud
        self.is_rmsd = is_rmsd
        self.is_fnc = is_fnc
        self.output_task = output_task


def user_input():
    parser = argparse.ArgumentParser()
    parser.add_argument('-r', '--residue', type=int, required=True)
    parser.add_argument('-a', '--atom', type=int)
    parser.add_argument('-f', '--frame', default=100, type=int)
    parser.add_argument('-n', '--number_of_jobs', default=1, type=int)
    parser.add_argument('--fnc', default=True)
    parser.add_argument('--rmsd', default=True)
    parser.add_argument('--contact_map', default=True) # =False to try Hermes MPIIO to work, default=True
    parser.add_argument('--point_cloud', default=True)
    parser.add_argument('--trajectory', default=False)
    parser.add_argument('--output_task', default=None)
    parser.add_argument('--output_filename', default=None)
    parser.add_argument('--adios-sst', action='store_true', default=False)
    parser.add_argument('--adios-bp', action='store_true', default=False)
    args = parser.parse_args()

    return args


if __name__ == "__main__":

    args = user_input()
    obj = SimEmulator(n_residues = args.residue,
            n_atoms = args.atom,
            n_frames = args.frame,
            n_jobs= args.number_of_jobs)

    # print(f"obj.output_filename = {obj.output_filename}")
    obj.output_settings(output_filename = args.output_filename,
            output_task= args.output_task,
            is_contact_map = args.contact_map,
            is_point_cloud = args.point_cloud,
            is_rmsd = args.rmsd,
            is_fnc = args.fnc)
    print(f"obj.output_filename = {obj.output_filename}")
    print(f"obj.output_task = {obj.output_task}")

    def runs(i):
        times = []
        if obj.output_task is not None:
            task_dir = OUTPUT_PATH + f"molecular_dynamics_runs/stage0000/task{obj.output_task}/"
        else:
            task_dir = OUTPUT_PATH + "molecular_dynamics_runs/stage0000/task{:04d}/".format(i)
        
        print(f"task_dir = {task_dir}")
        
        Path(task_dir).mkdir(parents=True, exist_ok=True)
        
        cms = obj.contact_maps()
        if cms is not None:
            obj.h5file(cms, 'contact_map', task_dir + obj.output_filename + ".h5")# + f"_ins_{i}.h5")
            
        pcs = obj.point_clouds()
        if pcs is not None:
            obj.h5file(pcs, 'point_cloud', task_dir + obj.output_filename + ".h5")#f"_ins_{i}.h5")

        dcd = obj.trajectories()
        if dcd is not None:
            obj.dcdfile(dcd, task_dir + obj.output_filename + ".dcd")#f"_ins_{i}.dcd")
        obj.pdbfile(None, task_dir + "dummy.pdb")#obj.output_filename + ".pdb")

        #print (max(times) - min(times), min(times), max(times) ) 
        return task_dir, obj.nbytes

    files = []
    fbytes = 0
    for i in range(obj.n_jobs):
        fname, fbyte = runs(i)
        fbytes += fbyte

    # with Pool(obj.n_jobs) as p:
        # res = (p.map(runs, list(range(obj.n_jobs))))
    # files = []
    # fbytes = 0
    # for fname, fbyte in res:
    #     files.append(fname)
    #     fbytes += fbyte

    print("total bytes written:{} in {} file(s)".format(fbytes, obj.n_jobs), file = sys.stderr)
    # obj.adios.close_conn() if obj.adios_on else None

    # # print("Error", file = sys.stderr )
    # # Add MPI for Hermes
    # MPI.Finalize()
    c_mpi_lib.c_mpi_finalize()
