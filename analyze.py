import pandas as pd
import sys
import re
import os

ko = 'OPEN'
kc = 'CLOSE'
kr = 'READ'
kw = 'WRITE'

ignore_line = ['Dataset_Dimension']

datasets = ['contact_map', 'point_cloud']


def humansize(nbytes):
    suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB']
    i = 0
    while nbytes >= 1000 and i < len(suffixes)-1:
        nbytes /= 1000.
        i += 1
    f = ('%.2f' % nbytes).rstrip('0').rstrip('.')
    return '%s %s' % (f, suffixes[i])

def read_block(acc_dict,t,f,count):
    count += 1
    acc_dict[count] = {}
    acc_dict[count]['type'] = t

    while True:

        line = f.readline()
        
        if line == '\n':
            break
        
        # tmp = line.replace("-- ", "")
        # tmp = line.replace("- ", "")
        tmp = line.strip().split(':')

        # if any(x in ignore_line for x in tmp):
        #     continue
        if len(tmp) == 0:
            break

        k = tmp[0].strip()
        k = k.replace("-", "")
        k = k.replace(" ", "")
        v = ""
        if len(tmp) > 1:
            v = tmp[1].strip()
            # v = v.replace("/", "")
            
        if k in acc_dict[count].keys():
            if 'Blob' in k:
                acc_dict[count][k].append(int(v))
        else:
            if 'Blob' in k:
                acc_dict[count][k] = [int(v)]
            else:
                acc_dict[count][k] = v
        # if count == 283:
        #     exit(1)
        # print("Line {}: {}".format(count, v))
    return count


def log_to_df(file):
    f = open(file,'r')
    count = 0
    acc_dict = {}

    print(" . Reading file data...")
  
    while True:
    
        # Get next line from file
        line = f.readline()
    
        # if line is empty
        # end of file is reached
        if not line:
            break
        # print("Line{}: {}".format(count, line.strip()))
        if kr in line:
            count = read_block(acc_dict,'read',f,count)
        if kw in line:
            count = read_block(acc_dict,'write',f,count)
        if ko in line:
            count = read_block(acc_dict,'open',f,count)
        if kc in line:
            count = read_block(acc_dict,'close',f,count)

    
    f.close()
    print(" . Reading file data done.")
    
    return pd.DataFrame(acc_dict)

  

def read_write_size(df, dsets, prefix=""):
    read_size = {}
    write_size = {}
    
    for ds in dsets:
        read_size[ds] = 0
        write_size[ds] = 0
    
    total_read = 0
    total_write = 0
    total_io = 0
    
    # currently problem with 2 datasets, it's recorded to point_cloud
    for id,row in df.iterrows():
        if row['type'] == 'read' and row['Access_Size'] > 0 :
            total_read += row['Access_Size']
            total_io += row['Access_Size']
            for ds in dsets:
                if row['Dataset_Name'] == ds:
                    read_size[ds] += row['Access_Size']

        if row['type'] == 'write' and row['Access_Size'] > 0 :
            total_write += row['Access_Size']
            total_io += row['Access_Size']
            for ds in dsets:
                if row['Dataset_Name'] == ds:
                    write_size[ds] += row['Access_Size']
    
    for ds in dsets:
        print("{} - {}\n- Read : {} \n- Write : {}\n"
            .format(prefix, ds, humansize(read_size[ds]), humansize(write_size[ds])))

    if 'sim' in prefix:
        print("{} - Total I/O : {}\n- Total Read : {}\n- Total Write : {}\n"
                .format(prefix, humansize(total_io), humansize(total_read), humansize(total_write))) 
    if 'agg' in prefix:
        print("{} - Total I/O : {}\n- Total Read : {}\n- Total Write : {}\n"
                .format(prefix, humansize(total_io), humansize(total_read), humansize(total_write))) 

def df_correct_type(df):
    string_cols = ['type', 'Filename', 
                    'Dataset_Name', 
                    'Access_Region_Mem_Type', 
                    'Dataset_Dimension',
                    'Blob']
    
    for c in df.columns:
        if c not in string_cols:
            df[c].fillna(-1,inplace=True)
            df[c] = df[c].astype('int64')
            # try:
            #     df[c] = df[c].astype('int64')
            #     # pd.to_numeric(df[c])
            # except:
            #     print(f"Error : {c} ")
            #     print(f"Error : {df[c]} ")
            #     print(df[df[c].isnull()])
            #     # print(df[df[c].isnull()])

def main():

    cmdargs = sys.argv

    if(len(cmdargs) < 2):
        exit("Please give input file")
    

    infile = cmdargs[1]

    print("Log to dataframe ...")
    df = log_to_df(infile)
    df = df.transpose()
    print("Dictionary to dataframe done.")

    # pd.set_option('max_columns', None)
    # print(df.head(3))
    # print(df.columns)
    # for c in ignore_line:
    #     del df[c]

    print("Analyzing read & write IO ...")
    df_correct_type(df)

    read_write_size(df,['/contact_map', '/point_cloud',''], infile)

    print("Writing to Excel ...")
    df.to_excel(f"{infile}.xlsx")
    # df.to_csv(f"{infile}.csv")
    print("Write to Excel done.")

if __name__ == "__main__":
    main()