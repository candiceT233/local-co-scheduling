# Problem Summary
- ```ADAPTER_MODE=WORKFLOW``` performance slow with small I/O transfer size in IOR
- ```ADAPTER_MODE=WORKFLOW``` hangs with my python simulation-aggregate app.
- Adjusting ```HERMES_PAGE_SIZE``` does improve Hermes performance, but when the size is small, metadata requires very large space.
- With policy ```MinimizeIoTime```, the RAM reserved space for ```buffer_pool_arena_percentage``` needs to be at least ~3.6x larger than all the files involved in 1 program (example: must reserve 360MB if read 50MB and write 50MB ).

# Test Setup
- w/ Hermes v0.9.0-beta
- All test with ```default_placement_policy: "MinimizeIoTime"```
- 2 tiers [RAM, SSD], ```capacities_gb: [1, 10]```
- buffer_pool and metadata percentage:
```
# Hermes memory management. The following 4 values should add up to 1.
# The percentage of Hermes memory to reserve for RAM buffers.
buffer_pool_arena_percentage: 0.35
# The percentage of Hermes memory to reserve for metadata.
metadata_arena_percentage: 0.6
# The percentage of Hermes memory to reserve for short term storage.
transient_arena_percentage: 0.05
```

## IOR
- total IO 16m, transfer size 2k
### ```ADAPTER_MODE=WORKFLOW``` adjusting ```HERMES_PAGE_SIZE```
- ```HERMES_PAGE_SIZE=8192``` (8k) reduces 50% IO time than default (1m)
- best Hermes performance about 2x slower than without using Hermes
- Example stderr log:
``` 
WARNING: Logging before InitGoogleLogging() is written to STDERR
I1128 15:36:19.896914 178367 config_parser.cc:527] ParseConfig-LoadFile
I1128 15:36:19.901610 178367 config_parser.cc:529] ParseConfig-LoadComplete
I1128 15:36:19.903115 178367 interceptor.cc:82] Adapter page size: 8192
I1128 15:36:20.198495 178367 posix.cc:53] MPI Init intercepted.
I1128 15:36:20.198544 178367 hermes.cc:419] Initializing hermes config
I1128 15:36:20.198560 178367 config_parser.cc:527] ParseConfig-LoadFile
I1128 15:36:20.203729 178367 config_parser.cc:529] ParseConfig-LoadComplete
I1128 15:36:20.232456 178367 hermes.cc:425] Initialized hermes config
I1128 15:36:20.233002 178367 posix.cc:83] Intercept open for filename: /mnt/ssd/mtang11/ior.out.00000000 and mode: 66 is tracked.
I1128 15:36:20.233191 178367 filesystem.cc:53] File not opened before by adapter
I1128 15:36:20.233268 178367 metadata_management.cc:493] Creating Bucket '/mnt/ssd/mtang11/ior.out.00000000'
I1128 15:36:20.233593 178367 bucket.h:476] Attaching blob '#main_lock' to Bucket '/mnt/ssd/mtang11/ior.out.00000000'
I1128 15:36:20.234004 178367 posix.cc:250] Intercept lseek offset:0 whence:0.
I1128 15:36:20.234076 178367 posix.cc:182] Intercept write.
I1128 15:36:20.234099 178367 filesystem.cc:140] Write called for filename: /mnt/ssd/mtang11/ior.out.00000000 on offset: 0 and size: 2048
I1128 15:36:20.234133 178367 filesystem.cc:201] Starting coordinate PUT blob: 0 off: 0 size: 2048 pid: 178367
I1128 15:36:20.234164 178367 filesystem.cc:209] Acquire lock: #main_lock for process: 178367
I1128 15:36:20.234180 178367 filesystem.cc:218] Starting uncoordinate PUT blob: 0 off: 0 size: 2048 pid: 178367
I1128 15:36:20.234190 178367 filesystem.cc:247] Create new blob (aligned) offset: 0 size: 2048
I1128 15:36:20.234267 178367 bucket.h:476] Attaching blob '0' to Bucket '/mnt/ssd/mtang11/ior.out.00000000'
I1128 15:36:20.234330 178367 filesystem.cc:213] Unlocking for process: 178367
I1128 15:36:20.234408 178367 posix.cc:316] Intercept fsync.
I1128 15:36:20.234422 178367 filesystem.cc:632] Filesystem Sync flushes 1 blobs to filename:/mnt/ssd/mtang11/ior.out.00000000.
I1128 15:36:20.234455 178367 metadata_management.cc:564] Creating VBucket '/mnt/ssd/mtang11/ior.out.00000000#0#sync'
I1128 15:36:20.234477 178367 vbucket.cc:74] Linking blob 0 in bucket /mnt/ssd/mtang11/ior.out.00000000 to VBucket /mnt/ssd/mtang11/ior.out.00000000#0#sync
I1128 15:36:20.234496 178367 vbucket.cc:151] Checking if blob 0 from bucket /mnt/ssd/mtang11/ior.out.00000000 is in this VBucket /mnt/ssd/mtang11/ior.out.00000000#0#sync
I1128 15:36:20.234570 178367 vbucket.cc:230] Attaching trait to VBucket /mnt/ssd/mtang11/ior.out.00000000#0#sync
I1128 15:36:20.234664 178367 buffer_organizer.cc:681] Flushing BlobID 4294967544 to file /mnt/ssd/mtang11/ior.out.00000000 at offset 0
I1128 15:36:20.234838 178367 vbucket.cc:357] Destroying VBucket /mnt/ssd/mtang11/ior.out.00000000#0#sync
I1128 15:36:20.239702 178367 posix.cc:250] Intercept lseek offset:2048 whence:0.
I1128 15:36:20.239857 178367 posix.cc:182] Intercept write.
...
I1128 15:36:59.819048 178367 filesystem.cc:213] Unlocking for process: 178367
I1128 15:36:59.819231 178367 posix.cc:316] Intercept fsync.
I1128 15:36:59.819260 178367 filesystem.cc:632] Filesystem Sync flushes 1 blobs to filename:/mnt/ssd/mtang11/ior.out.00000000.
I1128 15:36:59.819291 178367 metadata_management.cc:564] Creating VBucket '/mnt/ssd/mtang11/ior.out.00000000#0#sync'
I1128 15:36:59.819317 178367 vbucket.cc:74] Linking blob 2047 in bucket /mnt/ssd/mtang11/ior.out.00000000 to VBucket /mnt/ssd/mtang11/ior.out.00000000#0#sync
I1128 15:36:59.819365 178367 vbucket.cc:151] Checking if blob 2047 from bucket /mnt/ssd/mtang11/ior.out.00000000 is in this VBucket /mnt/ssd/mtang11/ior.out.00000000#0#sync
I1128 15:36:59.819442 178367 vbucket.cc:230] Attaching trait to VBucket /mnt/ssd/mtang11/ior.out.00000000#0#sync
I1128 15:36:59.819604 178367 buffer_organizer.cc:681] Flushing BlobID 4321773712 to file /mnt/ssd/mtang11/ior.out.00000000 at offset 16769024
I1128 15:36:59.819895 178367 vbucket.cc:357] Destroying VBucket /mnt/ssd/mtang11/ior.out.00000000#0#sync
I1128 15:36:59.823186 178367 posix.cc:316] Intercept fsync.
I1128 15:36:59.823375 178367 posix.cc:327] Intercept close(34)
I1128 15:36:59.823406 178367 posix.cc:329] 
I1128 15:36:59.823464 178367 bucket.cc:411] Destroying bucket '/mnt/ssd/mtang11/ior.out.00000000'
I1128 15:36:59.859156 178367 posix.cc:62] MPI Finalize intercepted.
```

## My App: simulation-aggregator
- total IO 98M
### ```ADAPTER_MODE=WORKFLOW``` hangs when blob being flushed
- HERMES_PAGE_SIZE is default 1m
- Example stderr log:
```
WARNING: Logging before InitGoogleLogging() is written to STDERR
I1128 16:07:46.362856 180371 config_parser.cc:527] ParseConfig-LoadFile
I1128 16:07:46.368744 180371 config_parser.cc:529] ParseConfig-LoadComplete
I1128 16:07:46.370271 180371 interceptor.cc:82] Adapter page size: 1048576
I1128 16:07:47.931859 180331 posix.cc:53] MPI Init intercepted.
I1128 16:07:47.931946 180331 hermes.cc:419] Initializing hermes config
I1128 16:07:47.931972 180331 config_parser.cc:527] ParseConfig-LoadFile
I1128 16:07:47.937826 180331 config_parser.cc:529] ParseConfig-LoadComplete
I1128 16:07:47.968562 180331 hermes.cc:425] Initialized hermes config
I1128 16:07:49.020303 180331 posix.cc:83] Intercept open for filename: /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 and mode: 2 is tracked.
I1128 16:07:49.020551 180331 posix.cc:83] Intercept open for filename: /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 and mode: 578 is tracked.
I1128 16:07:49.020766 180331 filesystem.cc:53] File not opened before by adapter
I1128 16:07:49.020861 180331 metadata_management.cc:493] Creating Bucket '/mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5'
I1128 16:07:49.021198 180331 bucket.h:476] Attaching blob '#main_lock' to Bucket '/mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5'
I1128 16:07:49.021443 180331 posix.cc:278] Intercepted fstat.
I1128 16:07:49.021842 180331 posix.cc:210] Intercept pwrite.
I1128 16:07:49.021867 180331 filesystem.cc:140] Write called for filename: /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 on offset: 0 and size: 96
I1128 16:07:49.021914 180331 filesystem.cc:201] Starting coordinate PUT blob: 0 off: 0 size: 96 pid: 180331
I1128 16:07:49.021951 180331 filesystem.cc:209] Acquire lock: #main_lock for process: 180331
I1128 16:07:49.021967 180331 filesystem.cc:218] Starting uncoordinate PUT blob: 0 off: 0 size: 96 pid: 180331
I1128 16:07:49.021978 180331 filesystem.cc:247] Create new blob (aligned) offset: 0 size: 96
I1128 16:07:49.022042 180331 bucket.h:476] Attaching blob '0' to Bucket '/mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5'
I1128 16:07:49.022090 180331 filesystem.cc:213] Unlocking for process: 180331
I1128 16:07:49.031759 180331 posix.cc:210] Intercept pwrite.
I1128 16:07:49.031783 180331 filesystem.cc:140] Write called for filename: /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 on offset: 0 and size: 40
I1128 16:07:49.031814 180331 filesystem.cc:201] Starting coordinate PUT blob: 0 off: 96 size: 40 pid: 180331
I1128 16:07:49.031832 180331 filesystem.cc:209] Acquire lock: #main_lock for process: 180331
I1128 16:07:49.031847 180331 filesystem.cc:218] Starting uncoordinate PUT blob: 0 off: 96 size: 40 pid: 180331
I1128 16:07:49.031862 180331 filesystem.cc:296] Modify existing blob (unaligned) offset: 96 size: 40
I1128 16:07:49.031883 180331 bucket.cc:113] Getting Blob 0 size from bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5
I1128 16:07:49.031916 180331 bucket.cc:153] Getting Blob 0 from bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5
I1128 16:07:49.031941 180331 bucket.cc:273] Deleting Blob 0 from bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5
I1128 16:07:49.032073 180331 bucket.h:476] Attaching blob '0' to Bucket '/mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5'
I1128 16:07:49.032109 180331 filesystem.cc:213] Unlocking for process: 180331
I1128 16:07:49
...
I1128 16:07:49.417225 180331 posix.cc:210] Intercept pwrite.
I1128 16:07:49.417238 180331 filesystem.cc:140] Write called for filename: /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 on offset: 0 and size: 96
I1128 16:07:49.417256 180331 filesystem.cc:201] Starting coordinate PUT blob: 0 off: 0 size: 96 pid: 180331
I1128 16:07:49.417273 180331 filesystem.cc:209] Acquire lock: #main_lock for process: 180331
I1128 16:07:49.417287 180331 filesystem.cc:218] Starting uncoordinate PUT blob: 0 off: 0 size: 96 pid: 180331
I1128 16:07:49.417296 180331 filesystem.cc:271] Modify existing blob (aligned) offset: 0 size: 96
I1128 16:07:49.417305 180331 bucket.cc:113] Getting Blob 0 size from bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5
I1128 16:07:49.417320 180331 filesystem.cc:284] Update blob 0 of size:1048576.
I1128 16:07:49.417387 180331 bucket.cc:153] Getting Blob 0 from bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5
I1128 16:07:49.417845 180331 bucket.h:476] Attaching blob '0' to Bucket '/mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5'
I1128 16:07:49.418066 180331 filesystem.cc:213] Unlocking for process: 180331
I1128 16:07:49.418174 180331 posix.cc:327] Intercept close(34)
I1128 16:07:49.418186 180331 posix.cc:329] 
I1128 16:07:49.418218 180331 filesystem.cc:632] Filesystem Sync flushes 10 blobs to filename:/mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5.
I1128 16:07:49.418278 180331 metadata_management.cc:564] Creating VBucket '/mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5#0#sync'
I1128 16:07:49.418305 180331 vbucket.cc:74] Linking blob 0 in bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 to VBucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5#0#sync
I1128 16:07:49.418325 180331 vbucket.cc:151] Checking if blob 0 from bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 is in this VBucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5#0#sync
I1128 16:07:49.418401 180331 vbucket.cc:74] Linking blob 1 in bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 to VBucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5#0#sync
...
I1128 16:07:49.418743 180331 vbucket.cc:74] Linking blob 9 in bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 to VBucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5#0#sync
I1128 16:07:49.418759 180331 vbucket.cc:151] Checking if blob 9 from bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 is in this VBucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5#0#sync
I1128 16:07:49.418799 180331 vbucket.cc:230] Attaching trait to VBucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5#0#sync
I1128 16:07:49.418907 180331 buffer_organizer.cc:681] Flushing BlobID 4294968752 to file /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 at offset 0
(hangs, the end of log)
```
### ```ADAPTER_MODE=SCRATCH``` adjusting ```HERMES_PAGE_SIZE```
- ```HERMES_PAGE_SIZE=128k``` reduces 50% IO time than default (1m)
- best Hermes performance about 3.5x slower than without using Hermes
- Example stderr log:
```
WARNING: Logging before InitGoogleLogging() is written to STDERR
I1128 15:59:46.322402 179703 config_parser.cc:527] ParseConfig-LoadFile
I1128 15:59:46.327682 179703 config_parser.cc:529] ParseConfig-LoadComplete
I1128 15:59:46.329638 179703 interceptor.cc:82] Adapter page size: 131072
I1128 15:59:47.582195 179663 posix.cc:53] MPI Init intercepted.
I1128 15:59:47.582268 179663 hermes.cc:419] Initializing hermes config
I1128 15:59:47.582289 179663 config_parser.cc:527] ParseConfig-LoadFile
I1128 15:59:47.586869 179663 config_parser.cc:529] ParseConfig-LoadComplete
I1128 15:59:47.612462 179663 hermes.cc:425] Initialized hermes config
I1128 15:59:47.617185 179663 posix.cc:83] Intercept open for filename: /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 and mode: 0 is tracked.
I1128 15:59:47.617347 179663 filesystem.cc:53] File not opened before by adapter
I1128 15:59:47.617434 179663 metadata_management.cc:490] Opening Bucket '/mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5'
I1128 15:59:47.617754 179663 bucket.h:476] Attaching blob '#main_lock' to Bucket '/mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5'
I1128 15:59:47.618081 179663 filesystem.h:342] Since bucket exists, should reset its size to: 10659361
I1128 15:59:47.618176 179663 posix.cc:278] Intercepted fstat.
I1128 15:59:47.618731 179663 posix.cc:195] Intercept pread.
I1128 15:59:47.618752 179663 filesystem.cc:353] Read called for filename: /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 (fd: 34) on offset: 0 and size: 8 (stored file size: 10659361 true file size: 0)
I1128 15:59:47.618783 179663 filesystem.cc:373] Mapping for read has 1 mapping.
I1128 15:59:47.618814 179663 bucket.cc:113] Getting Blob 0 size from bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5
I1128 15:59:47.618924 179663 filesystem.cc:409] Blob exists and need to read from Hermes from blob: 0.
I1128 15:59:47.618932 179663 filesystem.cc:411] Blob have data and need to read from hemes blob: 0 offset:0 size:8.
I1128 15:59:47.618940 179663 bucket.cc:153] Getting Blob 0 from bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5
I1128 15:59:47.619117 179663 posix.cc:195] Intercept pread.
...
I1128 15:59:51.582005 179663 posix.cc:210] Intercept pwrite.
I1128 15:59:51.582036 179663 filesystem.cc:140] Write called for filename: /mnt/ssd/mtang11/aggregate.h5 on offset: 0 and size: 48
I1128 15:59:51.582053 179663 filesystem.cc:201] Starting coordinate PUT blob: 0 off: 0 size: 48 pid: 179663
I1128 15:59:51.582069 179663 filesystem.cc:209] Acquire lock: #main_lock for process: 179663
I1128 15:59:51.582084 179663 filesystem.cc:218] Starting uncoordinate PUT blob: 0 off: 0 size: 48 pid: 179663
I1128 15:59:51.582093 179663 filesystem.cc:271] Modify existing blob (aligned) offset: 0 size: 48
I1128 15:59:51.582101 179663 bucket.cc:113] Getting Blob 0 size from bucket /mnt/ssd/mtang11/aggregate.h5
I1128 15:59:51.582116 179663 filesystem.cc:284] Update blob 0 of size:131072.
I1128 15:59:51.582130 179663 bucket.cc:153] Getting Blob 0 from bucket /mnt/ssd/mtang11/aggregate.h5
I1128 15:59:51.582216 179663 bucket.h:476] Attaching blob '0' to Bucket '/mnt/ssd/mtang11/aggregate.h5'
I1128 15:59:51.582284 179663 filesystem.cc:213] Unlocking for process: 179663
I1128 15:59:51.582983 179663 posix.cc:210] Intercept pwrite.
I1128 15:59:51.583019 179663 filesystem.cc:140] Write called for filename: /mnt/ssd/mtang11/aggregate.h5 on offset: 0 and size: 48
I1128 15:59:51.583038 179663 filesystem.cc:201] Starting coordinate PUT blob: 0 off: 0 size: 48 pid: 179663
I1128 15:59:51.583055 179663 filesystem.cc:209] Acquire lock: #main_lock for process: 179663
I1128 15:59:51.583070 179663 filesystem.cc:218] Starting uncoordinate PUT blob: 0 off: 0 size: 48 pid: 179663
I1128 15:59:51.583078 179663 filesystem.cc:271] Modify existing blob (aligned) offset: 0 size: 48
I1128 15:59:51.583087 179663 bucket.cc:113] Getting Blob 0 size from bucket /mnt/ssd/mtang11/aggregate.h5
I1128 15:59:51.583102 179663 filesystem.cc:284] Update blob 0 of size:131072.
I1128 15:59:51.583134 179663 bucket.cc:153] Getting Blob 0 from bucket /mnt/ssd/mtang11/aggregate.h5
I1128 15:59:51.583220 179663 bucket.h:476] Attaching blob '0' to Bucket '/mnt/ssd/mtang11/aggregate.h5'
I1128 15:59:51.583281 179663 filesystem.cc:213] Unlocking for process: 179663
I1128 15:59:51.583413 179663 posix.cc:327] Intercept close(34)
I1128 15:59:51.583422 179663 posix.cc:329] 
I1128 15:59:51.583496 179663 bucket.cc:392] Closing bucket '/mnt/ssd/mtang11/aggregate.h5'
I1128 15:59:51.590910 179663 posix.cc:62] MPI Finalize intercepted.
```
