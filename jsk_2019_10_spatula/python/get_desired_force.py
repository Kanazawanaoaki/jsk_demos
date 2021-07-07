import json
import rosbag
import os
import numpy as np

resample = True
#path_bag = "/home/leus/force_different_spatula_pos/test"
#path = "/home/leus/force_feedack_exp_19_01"
path = "/home/leus/force_bag_01_24/force_reference"
path_json = "%s/force.json" % path

data = {}
force_dict = {}
ts_dict = {}
indices = {}
n_t_dict = {}
labels = []
#probably good to move as much as posssible to offline computation
n_time_action = {"av3wall-0-1":1,"av3wall-0-2":1,"av3wall-0-3":1,"av3wall-0-4":1,"av3wall-1-1":1,"av3wall-1-2":1,"av3wall-1-3":1,"av3wall-1-4":1,"av3wall-2-1":1,"av3wall-2-2":1,"av3wall-2-3":1,"av3wall-2-4":1,"av3wall-3-1":1,"av3wall-3-2":1,"av3wall-3-3":1,"av3wall-3-4":1} #specifies how long an action takes in seconds
#if we have a publishing rate of 100 Hz we have n_sample = 100 * n_time

used_labels = ["gain_02","gain_04","gain_06","gain_08","short","long"]#["short","long","long_adapted","short_2","short_3","long_2","short_4"]

def main():
    read_bag()
    save_json()
    

def read_bag():
    force = {}
    force["larm"] = []
    force["rarm"] = []
    n_exp = 0
    for label in used_labels:
        path_bag = "%s/%s" % (path,label)
        n_exp = n_exp + len(os.listdir(path_bag))

    for label in used_labels:
        print label
        #path_bag = "/home/leus/force_different_spatula_pos/transfer/%s" % label
        path_bag = "%s/%s" % (path,label)

        for doc in os.listdir(path_bag):
            if doc.split(".")[-1] != "bag":
                continue
            bag = rosbag.Bag("%s/%s" % (path_bag,doc))
            print "reading document %s" % doc
            labels.append(label)

            ts = []
            start_ts = {}
            stop_ts = {}
            force["larm"] = []
            force["rarm"] = []
            for topic, msg, t in bag.read_messages(''):

                if topic == "/endeffector_force":
                    force["larm"].append(msg.larm)
                    force["rarm"].append(msg.rarm)
                    ts.append(t.to_sec())

                if topic == "/semantic_annotation":
                    [action,flag_type] = msg.data.split("_")
                    if resample and action not in n_time_action.keys():
                        continue
                    if flag_type == "start":
                        start_ts[action] = t.to_sec()
                        print action
                        if resample:
                            n_time = n_time_action[action]
                            n_sample = 100*n_time
                    if flag_type == "end":
                        stop_ts[action] = t.to_sec()
            if resample:
                split_sequence(ts,force,start_ts,stop_ts,n_exp,n_time,n_sample)
            else:
                split_sequence(ts,force,start_ts,stop_ts,n_exp)

def split_sequence(ts,force,start_ts,stop_ts,n_exp,n_time=None,n_sample=None):
    force_action = {}
    force_action["larm"] = []
    force_action["rarm"] = []
    for action in start_ts.keys():
        if action not in stop_ts.keys():
            continue
        ts = np.array(ts)
        start_index = np.argmin(np.abs(ts-start_ts[action]))
        stop_index = np.argmin(np.abs(ts-stop_ts[action]))
        ts_list_action = ts[start_index:stop_index] - ts[start_index]
        force_action["larm"] = force["larm"][start_index:stop_index]
        force_action["rarm"] = force["rarm"][start_index:stop_index]

        if action in force_dict.keys():
            if n_time and n_sample:
                update_force_dict(action,force_action,ts_list_action,n_time,n_sample)   
            else:
                update_force_dict(action,force_action,ts_list_action)
        else:
            n_t = np.shape(force_action["larm"])[0]
            if n_time and n_sample:
                force_array = np.zeros([n_sample,np.shape(force_action["larm"])[1],n_exp])
            else:
                force_array = np.zeros([int(round(1.5*n_t)) ,np.shape(force_action["larm"])[1],n_exp])
                ts_array = np.zeros([int(round(1.5*n_t)),n_exp])
                ts_dict[action] = ts_array

            force_dict[action] = {}
            force_dict[action]["larm"] = force_array
            force_dict[action]["rarm"] = force_array
            indices[action] = 0
            n_t_dict[action] = []
            
            if n_time and n_sample:
                update_force_dict(action,force_action,ts_list_action,n_time,n_sample)   
            else:
                update_force_dict(action,force_action,ts_list_action)
                


def resample(ts,signal,n_time,n_sample):
    stretched_signal = np.interp(np.linspace(0,n_time,n_sample),ts,signal)
    return stretched_signal

def update_force_dict(action,force,ts,n_time=None,n_sample=None):
    for arm in ["larm","rarm"]:
        force_array = np.array(force_dict[action][arm])
        if n_time and n_sample:
            for i in range(np.shape(force[arm])[1]):
                force_array[:,i,indices[action]] = resample(ts,np.array(force[arm])[:,i],n_time,n_sample)
            n_t = n_sample
        else:
            n_t = np.shape(force[arm])[0]
            force_array[0:n_t,0:np.shape(force[arm])[1],indices[action]] = force[arm]
        force_dict[action][arm] = force_array.tolist()
        #print "ts shaope list"
        #print np.shape(ts)
        if not (n_time and n_sample):
            ts_array = np.array(ts_dict[action])
            #print ",,,,,,,,,,,,,,,,,,,"
            #print np.shape(ts_array)
            ts_array[0:n_t,indices[action]] = ts
            ts_dict[action] = ts_array.tolist()
            #print "ts shape dict"
            #print np.shape(ts_dict[action])
        n_t_dict[action].append(n_t)
    indices[action] = indices[action] + 1

def save_json():
    data["force"] = force_dict
    data["n_exp"] = indices
    data["label"] = labels
    data["n_t"] = n_t_dict
    if not resample:
        data["ts"] = ts_dict
    json_dict = json.dumps(data)
    f = open(path_json,"w")
    f.write(json_dict)
    f.close()

def validate_json():
    #for validation
    f = open(path_json,"r")
    test = f.read()
    f.close()
    exec("dict2 = %s" % test)
    print dict2.keys()


if __name__ == "__main__":
    main()