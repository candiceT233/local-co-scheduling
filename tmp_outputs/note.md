# Problem Summary

# Test Setup
- All test with ```default_placement_policy: "MinimizeIoTime"```
- 2 tiers [RAM, SSD], RAM reserved 1GB
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
### ```ADAPTER_MODE=WORKFLOW``` adjusting HERMES_PAGE_SIZE
- ```HERMES_PAGE_SIZE=8192``` (8k) reduces 50% IO time than default (1m)
- best Hermes performance about 2x slower than default
Example stderr log:
> WARNING: Logging before InitGoogleLogging() is written to STDERR
I1128 15:36:19.794088 178363 config_parser.cc:527] ParseConfig-LoadFile
I1128 15:36:19.799248 178363 config_parser.cc:529] ParseConfig-LoadComplete
I1128 15:36:19.800767 178363 interceptor.cc:82] Adapter page size: 8192
WARNING: Logging before InitGoogleLogging() is written to STDERR
I1128 15:36:19.839440 178366 config_parser.cc:527] ParseConfig-LoadFile
I1128 15:36:19.844674 178366 config_parser.cc:529] ParseConfig-LoadComplete
I1128 15:36:19.846575 178366 interceptor.cc:82] Adapter page size: 8192
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

## My App: simulation-aggregator
- total IO 98M
### ```ADAPTER_MODE=WORKFLOW``` hangs when blob being flushed
Example stderr log:
> I1128 14:08:09.447654 172191 posix.cc:327] Intercept close(24)
I1128 14:08:09.447666 172191 posix.cc:329] 
I1128 14:08:09.447687 172191 filesystem.cc:632] Filesystem Sync flushes 1 blobs to filename:/mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5.
I1128 14:08:09.447731 172191 metadata_management.cc:564] Creating VBucket '/mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5#0#sync'
I1128 14:08:09.447757 172191 vbucket.cc:74] Linking blob 0 in bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 to VBucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5#0#sync
I1128 14:08:09.447778 172191 vbucket.cc:151] Checking if blob 0 from bucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 is in this VBucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5#0#sync
I1128 14:08:09.447861 172191 vbucket.cc:230] Attaching trait to VBucket /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5#0#sync
I1128 14:08:09.447965 172191 buffer_organizer.cc:681] Flushing BlobID 4294968776 to file /mnt/ssd/mtang11/molecular_dynamics_runs/stage0000/task0000/residue_100.h5 at offset 0

### ```ADAPTER_MODE=SCRATCH``` adjusting ```HERMES_PAGE_SIZE```
- ```HERMES_PAGE_SIZE=128k``` reduces 50% IO time than default (1m)
- best Hermes performance about 3.5x slower than default
