
/* Local dataset routine prototypes */
H5VL_provenance_t * _dset_wrap_under(void *under, H5VL_provenance_t *upper_o,
    hid_t blob_id, size_t size, void** req);
blob_prov_info_t * add_blob_node(file_prov_info_t *file_info, void * blob_id, 
    size_t size, H5O_token_t token);

static H5VL_provenance_blob_t *H5VL_provenance_new_blob_obj(prov_helper_t* helper);

/*-------------------------------------------------------------------------
 * Function:    H5VL__provenance_new_blob_obj
 *
 * Purpose:     Create a new PROVENANCE object for an blob object
 *
 * Return:      Success:    Pointer to the new PROVENANCE_BLOB object
 *              Failure:    NULL
 *
 * Programmer:  Candice Tang
 *              Monday, December 3, 2018
 *
 *-------------------------------------------------------------------------
 */
static H5VL_provenance_blob_t *
H5VL_provenance_new_blob_obj()
{
//    unsigned long start = get_time_usec();
    H5VL_provenance_blob_t *new_blob_obj;

    // assert(helper);

    new_blob_obj = (H5VL_provenance_blob_t *)calloc(1, sizeof(H5VL_provenance_blob_t));
    // new_blob_obj->prov_helper = helper;
    new_blob_obj->my_type = 123;
    ptr_cnt_increment(new_blob_obj->prov_helper);
    //TOTAL_PROV_OVERHEAD += (get_time_usec() - start);
    return new_blob_obj;
} /* end H5VL__provenance_new_blob_obj() */

blob_prov_info_t *new_blob_info(file_prov_info_t *root_file, 
    dataset_prov_info_t *root_dset, H5O_token_t token, 
    size_t size, void *blob_id)
{
    // const char *name, H5O_token_t token

    blob_prov_info_t *info;
    const char * name = (const char *) root_dset->obj_info.name;

    info = (blob_prov_info_t *)calloc(1, sizeof(blob_prov_info_t));
    info->obj_info.prov_helper = PROV_HELPER;
    info->obj_info.file_info = root_file;
    info->obj_info.name = name ? strdup(name) : NULL;
    info->obj_info.token = token;

    info->blob_id = blob_id;
    info->access_size = size;

    // initialize order_id values
    info->sorder_id=0;
    info->porder_id=0;
    info->pdset_sorder_id = 0;
    info->pdset_porder_id = 0;
    info->pfile_sorder_id = 0;
    info->pfile_porder_id = 0;

    return info;
}


blob_prov_info_t * new_blob_prov_info(file_prov_info_t * file_info,
    dataset_prov_info_t * dset_info, H5O_token_t token,
    size_t size, void *blob_id)
{

    hid_t dcpl_id = -1;
    hid_t dt_id = -1;
    hid_t ds_id = -1;
    H5O_token_t token;


    // TODO(candice): handel parallel case for casting to dataset_prov_info_t?
    // Does parallel case have different obj for I/O in hdf5?
    assert(file_info);
    assert(dset_info);

    blob_info = new_blob_info(file_info, dset_info, token, size, blob_id);

    return blob_info;
}

/*
 * TODO (candice) : adding blob node to dset_info
 * for tracing blob objects
*/
blob_prov_info_t * add_blob_node(file_prov_info_t *file_info, void * blob_id, 
    size_t size, H5O_token_t token)
{
    unsigned long start = get_time_usec();
    blob_prov_info_t* cur;
    int cmp_value;

    H5VL_provenance_t *file = (H5VL_provenance_t *)obj;
    file_prov_info_t * file_info = (file_prov_info_t*)file->generic_prov_info;

    dataset_prov_info_t * dset_info = (dataset_prov_info_t*)file_info->opened_datasets; 

    assert(file_info);
    assert(dset_info);

    // Find attribute in linked list of opened attributes
    cur = dset_info->used_blobs;
    while (cur) {
        if (H5VLtoken_cmp(blob->under_object, blob->under_vol_id,
                          &(cur->obj_info.token), &token, &cmp_value) < 0)
	    fprintf(stderr, "H5VLtoken_cmp error");
        if (cmp_value == 0)
            break;
        cur = cur->next;
    }

    if(!cur) {
        // Allocate and initialize new blob node
        cur = new_blob_prov_info(file_info, dset_info, token, size, blob_id);

        // Add to linked list
        cur->next = dset_info->used_blobs;
        dset_info->used_blobs = cur;
        dset_info->used_blob_cnt++;
    }

    // // Increment refcount on attribute
    // cur->obj_info.ref_cnt++;

    // BLOB_LL_TOTAL_TIME += (get_time_usec() - start);
    return cur;
}


//need a dumy node to make it simpler
int rm_dataset_node(prov_helper_t *helper, void *under_obj, hid_t under_vol_id, dataset_prov_info_t *dset_info)
{
    unsigned long start = get_time_usec();
    file_prov_info_t *file_info;
    dataset_prov_info_t *cur;
    dataset_prov_info_t *last;
    int cmp_value;

    // Decrement refcount
    dset_info->obj_info.ref_cnt--;

    // If refcount still >0, leave now
    if(dset_info->obj_info.ref_cnt > 0)
        return dset_info->obj_info.ref_cnt;

    // Refcount == 0, remove dataset from file info
    file_info = dset_info->obj_info.file_info;
    assert(file_info);
    assert(file_info->opened_datasets);

    cur = file_info->opened_datasets;
    last = cur;
    while(cur){
        if (H5VLtoken_cmp(under_obj, under_vol_id, &(cur->obj_info.token),
                          &(dset_info->obj_info.token), &cmp_value) < 0)
	    fprintf(stderr, "H5VLtoken_cmp error");
	if (cmp_value == 0) {//node found
            //special case: first node is the target, ==cur
            if(cur == file_info->opened_datasets)
                file_info->opened_datasets = file_info->opened_datasets->next;
            else
                last->next = cur->next;

            dataset_info_free(cur);

            file_info->opened_datasets_cnt--;
            if(file_info->opened_datasets_cnt == 0)
                assert(file_info->opened_datasets == NULL);

            // Decrement refcount on file info
            DS_LL_TOTAL_TIME += (get_time_usec() - start);
            rm_file_node(helper, file_info->file_no);

            return 0;
        }

        last = cur;
        cur = cur->next;
    }

    DS_LL_TOTAL_TIME += (get_time_usec() - start);
    //node not found.
    return -1;
}


void file_ds_created(file_prov_info_t *info)
{
    assert(info);
    if(info)
        info->ds_created++;
}

//counting how many times datasets are opened in a file.
//Called by a DS
void file_ds_accessed(file_prov_info_t* info)
{
    assert(info);
    if(info)
        info->ds_accessed++;
}

/* 
 * TODO (candice) : adding blob node to dset_info
 * under: blob need to be wrapped
 * take different input than _obj_wrap_under
 */
H5VL_provenance_t * _dset_wrap_under(void *under, H5VL_provenance_t *upper_o,
    hid_t blob_id, size_t size, void** req)
{
    H5VL_provenance_t *obj;
    file_prov_info_t *file_info = NULL;

    if (under) {
        H5O_info2_t oinfo;
        H5O_token_t token;
        unsigned long file_no;

        obj = H5VL_provenance_new_obj(under, upper_o->under_vol_id, upper_o->prov_helper);

        get_native_info(under, H5I_VOL, upper_o->under_vol_id,H5P_DEFAULT, &oinfo);
        token = oinfo.token;

        /* Check for async request */
        if (req && *req)
            *req = H5VL_provenance_new_obj(*req, upper_o->under_vol_id, upper_o->prov_helper);

        obj->generic_prov_info = add_blob_node(under, blob_id, size, token);

    } /* end if */
    else
        obj = NULL;

    return obj;
}

//This function makes up a fake upper layer obj used as a parameter in _obj_wrap_under(..., H5VL_provenance_t* upper_o,... ),
//Use this in H5VL_provenance_wrap_object() ONLY!!!
H5VL_provenance_t * _fake_obj_new(file_prov_info_t *root_file, hid_t under_vol_id)
{
    H5VL_provenance_t* obj;

    obj = H5VL_provenance_new_obj(NULL, under_vol_id, PROV_HELPER);
    obj->my_type = H5I_FILE;  // FILE should work fine as a parent obj for all.
    obj->generic_prov_info = (void*)root_file;

    return obj;
}

struct H5VL_prov_blob_info_t {
    object_prov_info_t obj_info;        // Generic prov. info
                                        // Must be first field in struct, for
                                        // generic upcasts to work
    // dataset_prov_info_t
    
    /* candice added for recording blob start */
    // int blob_put_cnt;
    // size_t total_bytes_blob_put;
    // hsize_t total_blob_put_time;
    // int blob_get_cnt;
    // size_t total_bytes_blob_get;
    // hsize_t total_blob_get_time;
    /* candice added for recording blob end */
    int blob_id;
    int access_size;
    int sorder_id;
    int porder_id;
    int pdset_sorder_id;
    int pdset_porder_id;
    int pfile_sorder_id;
    int pfile_porder_id;

#ifdef H5_HAVE_PARALLEL
    int ind_blob_get_cnt;
    int ind_blob_put_cnt;
    int coll_blob_get_cnt;
    int coll_blob_put_cnt;
    int broken_coll_blob_get_cnt;
    int broken_coll_dblob_put_cnt;
#endif /* H5_HAVE_PARALLEL */
    int access_type; // 0 for put, 1 for get
    int access_cnt;
    
    blob_prov_info_t *next;
};


typedef struct H5VL_provenance_blob_t {
    int my_type;         /* obj type, dataset, datatype, etc. */
    // prov_helper_t *prov_helper; /* pointer shared among all layers, one per process. */
    void *generic_prov_info;    /* Pointer to a class-specific prov info struct. */
                                /* Should be cast to layer-specific type before use, */
                                /* such as file_prov_info, dataset_prov_info. */
} H5VL_provenance_blob_t;