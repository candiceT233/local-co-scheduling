# Note
* Object Reuse on contact_map (in VOL, without VFD): 
    * On the HDF5 VOL layer, found a token type that seems is able to reveal pattern in subset data reuse
    * The object token type represent unique and permanent identifiers for referencing HDF5 objects within a container, designed to replace object address (where it may not be meaningful)
    * A single operation must be called along with this token to reveal the unique blob_buffer address (e.g. a print statement must print token first then print the buffer)
        * Observe some pattern shown in SIM and AGG.
            * SIM: unique buffers is read with different number of times (VFD, there is no observation of address reuse)

            * AGG: unique buffers is read/write different times, but the read and write times are the same
                * There seems to be some access ordering in the read/write of a unique blob (On VFD, the file address are out-of-order, but does not show reuse)

## Object reuse example on aggregate.py
In log line 80+, read phase:
```
PROVENANCE VOL BLOB Get
{ H5VL_provenance_blob_get(1) : {blob_id : 0x292e90c, access_size : 9212, }}
{ add_blob_node(1) : {token : 0x233d5e0, blob_id : 0x7f6de9e43a41, access_size : 43182348, buffer : 0x23fc }}
```
In log line 998 +, write phase:
```
PROVENANCE VOL BLOB Put
{ H5VL_provenance_blob_put(1) : {blob_id : 0x292e8fc, access_size : 9212, }}
{ add_blob_node(1) : {token : 0x7ffdca37d690, blob_id : 0x7f6de9e3f80b, access_size : 43182332, buffer : 0x23fc }}
```


## Unique object access example
```
size_of_token : 16
{ H5VL_provenance_blob_put(1) : {blob_id : 0x300236c, access_size : 9204, }}
{ add_blob_node(1) : {token : 0x7ffdace9ef40, blob_id : 0x7f9902e1b80b, access_size : 50340716, buffer : 0x23f4 }}
{ add_blob_node(2) : {blob_id : 0x300236c, access_size : 9204, buffer : 0x2ff9250, token : 0x7ffdace9ef40 }}
{ H5VL_provenance_blob_put(2) : {blob_id : 0x300236c, access_size : 9204, }}
```

