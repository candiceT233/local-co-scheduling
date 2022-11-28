# Problems
- All test with For policy MinimizeIoSize
- RAM reserved 1GB (350m usable, the rest for metadata)

## IOR
- total IO 16m, transfer size 2k
### ```ADAPTER_MODE=WORKFLOW``` adjusting HERMES_PAGE_SIZE
- ```HERMES_PAGE_SIZE=8192``` (8k) reduces 50% IO time than default (1m)
- best Hermes performance about 2x slower than default


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
