#!/usr/bin/env python
import rosbag
import matplotlib.pyplot as plt
import numpy as np
import os
import time

from matplotlib import cm
from matplotlib.colors import ListedColormap, LinearSegmentedColormap

task = "scrape"
window = 10
plot_radial_force = True


def main():
    read_bag()
    #read_json()
    #read_json_no_time()
    #read_json_debug()

def read_json_debug():
    path = "/home/leus/force_feedack_exp_19_01"
    path_json = "%s/force.json" % path

    #KO hack to debug compare_force
    fig, axs = plt.subplots(2, 1)
    t1 = time.time()
    f = open(path_json,"r")
    test = f.read()
    f.close()
    exec("dict1 = %s" % test)
    dict2 = dict1["force"]
    action = "av3wall-1-2"

    for i in range(dict1["n_exp"][action]):
        label = dict1["label"][i]
        if label != "long" and label != "short":
            continue
        n_t = dict1["n_t"][action]
        print n_t
        force_l = np.array(dict2[action]["larm"])
        force_r = np.array(dict2[action]["rarm"])
        force = {}
        force["larm"] = force_l[0:n_t[i],:,i]
        force["rarm"] = force_r[0:n_t[i],:,i]
        plot_force_debug_compare_force(force,label,fig=fig,axs=axs)
    plt.show()

def read_json():
    #path = "/home/leus/force_feedack_exp_19_01"
    path = "/home/leus/force_bag_01_24/force_reference"
    path_json = "%s/force.json" % path

    #KO hack to debug compare_force
    fig, axs = plt.subplots(8, 1)
    t1 = time.time()
    f = open(path_json,"r")
    test = f.read()
    f.close()
    exec("dict1 = %s" % test)
    dict2 = dict1["force"]
    action = "av3wall-0-1"
    print dict1.keys()
    print dict1["n_exp"].keys()
    for i in range(dict1["n_exp"][action]):
        label = dict1["label"][i]
        #if label != "long" and label != "short":
        if label not in ["short","long","long_adapted","short_2","short_3","long_2","short_4"]:
            continue
        n_t = dict1["n_t"][action]
        ts = np.array(dict1["ts"][action])[0:n_t[i],i]
        force_l = np.array(dict2[action]["larm"])
        force_r = np.array(dict2[action]["rarm"])
        force = {}
        force["larm"] = force_l[0:n_t[i],:,i]
        force["rarm"] = force_r[0:n_t[i],:,i]
        first = True
        if first:
            plot_force(ts,force,label,fig=fig,axs=axs)
            first = False
        else:
            plot_force(ts,force,label,fig=fig,axs=axs,set_label=False)
    plt.show()

def read_json_no_time():
    path_json = "force.json"

    #KO hack to debug compare_force
    fig, axs = plt.subplots(8, 1)
    t1 = time.time()
    f = open(path_json,"r")
    test = f.read()
    f.close()
    exec("dict1 = %s" % test)
    dict2 = dict1["force"]
    action = "av3wall-0-1"
    print dict1["n_exp"].keys()
    for i in range(dict1["n_exp"][action]):
        label = dict1["label"][i]
        #if label != "long" and label != "short":
        if label not in ["gain_02","gain_04","gain_06","gain_08","short","long"]:#["short","long","long_adapted","short_2","short_3","long_2","short_4"]:
            continue
        n_t = dict1["n_t"][action]
        force_l = np.array(dict2[action]["larm"])
        force_r = np.array(dict2[action]["rarm"])
        force = {}
        force["larm"] = force_l[:,:,i]
        force["rarm"] = force_r[:,:,i]

        plot_force_no_time(force,label,fig=fig,axs=axs,set_label=False)
    plt.show()

def read_bag():
    only_z = False
    if only_z:
        fig, axs = plt.subplots(2, 1)
    else:
        fig, axs = plt.subplots(8, 1)
    i = 0
    for label in ["long","long_2","short","short_2"]:#"gain_exp",#"intermediate"]:#,"movement_exp","scrape_0_long"]:#gain_exp",#,"long_old","short_old"]:#["short","short_old","short_2","short_3","short_4","long","long_2"]:#["short","long","long_adapted","short_2","short_3","long_2","short_4"]:
        #path = "/home/leus/force_different_spatula_pos/transfer/%s" % label
        #path = "/home/leus/force_feedack_exp_19_01/%s" % label
        path = "/home/leus/force_bag_01_24/%s" % label
        #path = "/home/leus/force_bag_01_24/clean_0/%s" % label

        if label == "long" or label == "long_2":
            color_code = 0
        color_table = np.linspace(0.1,0.8,11)
        print color_table
        if label == "short" or label == "short_2":
            color_code = 1.0
        first = True
        docs = np.sort(os.listdir(path))
        for doc in docs:
            if label == "gain_exp":
                color_code = color_table[i]
                print color_code
                i = i+1
            if doc.split(".")[-1] != "bag":
                print "skipping file %s as it is not a bag file" % doc
                continue
            print doc

            force = {"larm":[],"rarm":[]}
            #force_ts = {}

            effort = {"larm": {"desired":[],"error":[],"actual":[]},"rarm": {"desired":[],"error":[],"actual":[]}}
            position = {"larm": {"desired":[],"error":[],"actual":[]},"rarm": {"desired":[],"error":[],"actual":[]}}
            velocity = {"larm": {"desired":[],"error":[],"actual":[]},"rarm": {"desired":[],"error":[],"actual":[]}}


            bag = rosbag.Bag("%s/%s" % (path,doc))
            start_ts = None
            stop_ts = None
            ts = []

            for topic, msg, t in bag.read_messages(''):
                if topic == "/endeffector_force":
                    force["larm"].append(msg.larm)
                    force["rarm"].append(msg.rarm)
                    ts.append(t)

                if topic == "/semantic_annotation":
                    if task == "scrape":
                        #print msg
                        [av,flag_type] = msg.data.split("_")
                        #[av,scrape_type,bowl_position,flag_type] = msg.data.split("_")
                        #if av == "av1wall" and flag_type == "start":
                        if av == "av3wall-0-1" and flag_type == "start":
                        #if msg.data == "av1wall_0_1_start":
                            start_ts = t
                        #if av == "av4wall" and flag_type == "end":
                        if av == "av3wall-0-1" and flag_type == "end":
                        #if msg.data == "av4wall_3_4_end":
                            stop_ts = t

                    elif task == "transfer":
                        [av,flag_type] = msg.data.split("_")
                        if av == "av3transfer" and flag_type == "start":
                            start_ts = t
                        if av == "av7transfer" and flag_type == "end":
                            stop_ts = t

            ts = np.array(ts)
            #force_ts{doc} = ts
            #print ts
            #print start_ts
            start_index = np.argmin(np.abs(ts-start_ts))
            stop_index = np.argmin(np.abs(ts-stop_ts))
            ts_action = ts_to_sec(ts[start_index:stop_index])
            #print "task length in time:"
            #print type(stop_ts) #.sec - start_ts.sec
            #print stop_ts.to_sec() - start_ts.to_sec()
            #print "task length in samples"
            #print stop_index - start_index
            if first:
                #plot_force(ts_action,force,label,start_index,stop_index,fig,axs,True)
                plot_force_color_map(ts_action,force,label,start_index,stop_index,fig,axs,True,color_code,only_z)
                first = False
            else:
                #plot_force(ts_action,force,label,start_index,stop_index,fig,axs,False)
                plot_force_color_map(ts_action,force,label,start_index,stop_index,fig,axs,False,color_code,only_z)
    plt.show()

def ts_to_sec(ts):
    ts_sec = []
    first = True
    for t in ts:
        if first:
            first_ts = t
            first = False
        ts_sec.append(t.to_sec()-first_ts.to_sec())

    return ts_sec

def resample(ts,signal,length):
    #stretched_signal = np.interp(np.linspace(0,len(signal),length),range(len(signal)),signal)
    stretched_signal = np.interp(np.linspace(ts[0],ts[-1],length),ts,signal)
    return stretched_signal

def mean_filter(signal,window):
    if window == 1:
        return signal
    filtered_signal = 1/float(window) * np.convolve(signal, np.ones([window]))
    return filtered_signal[window:len(filtered_signal)-window]

def mean_filter_strided(signal, window):
    if window == 1:
        return signal
    m = int(round(len(signal)/window))
    filtered_signal = 1/float(window) * np.matmul(np.ones([1,window]),np.transpose(np.reshape(signal[0:window*m],[m,window])))
    filtered_signal = filtered_signal.flatten()
    return filtered_signal.tolist()

def plot_force_resampled(ts,force,label,start_index = 0,stop_index = -1,fig=None,axs=None,set_label = True):
    if label == "short" or label == "shorter" or label == "short_2" or label == "short_3" or label=="short_4":
        color = "lightseagreen"
    elif label == "long_2" or label == "long" or label == "long_old":
        color = "maroon"
    elif label == "long_adapted":
        color = "navy"
    else:
        color = "grey"

    if fig is None or axs is None:
        fig, axs = plt.subplots(6, 1)

    print np.shape(force["larm"])

    #line0, = axs[0].plot(mean_filter(np.transpose(force["larm"])[0][start_index:stop_index],window),color)
    print "---shape resample----"
    print np.shape(resample(ts,np.transpose(force["larm"])[0][start_index:stop_index],100))
    line0, = axs[0].plot(resample(ts,np.transpose(force["larm"])[0][start_index:stop_index],100),color)
    line1, = axs[1].plot(resample(ts,np.transpose(force["larm"])[1][start_index:stop_index],100),color)
    line2, = axs[2].plot(resample(ts,np.transpose(force["larm"])[2][start_index:stop_index],100),color)
    

    line3, = axs[3].plot(resample(ts,np.transpose(force["rarm"])[0][start_index:stop_index],100),color)
    line4, = axs[4].plot(resample(ts,np.transpose(force["rarm"])[1][start_index:stop_index],100),color)
    line5, = axs[5].plot(resample(ts,np.transpose(force["rarm"])[2][start_index:stop_index],100),color)

    if plot_radial_force:
        line6, = axs[6].plot(resample(ts,np.transpose(force["larm"])[3][start_index:stop_index],100),color)
        line7, = axs[7].plot(resample(ts,np.transpose(force["rarm"])[3][start_index:stop_index],100),color)
        axs[6].set_ylabel("Fr larm")
        axs[7].set_ylabel("Fr rarm")
        axs[6].legend()
        axs[7].legend()

    if set_label:
        line0.set_label(label)
        line1.set_label(label)
        line2.set_label(label)
        line3.set_label(label)
        line4.set_label(label)
        line5.set_label(label)
        if plot_radial_force:
            line6.set_label(label)
            line7.set_label(label)

    axs[0].set_ylabel("Fx larm")
    axs[1].set_ylabel("Fy larm")
    axs[2].set_ylabel("Fz larm")
    axs[3].set_ylabel("Fx rarm")
    axs[4].set_ylabel("Fy rarm")
    axs[5].set_ylabel("Fz rarm")

    axs[0].legend()
    axs[1].legend()
    axs[2].legend()
    axs[3].legend()
    axs[4].legend()
    axs[5].legend()

def plot_force_no_time(force,label,start_index = 0,stop_index = -1,fig=None,axs=None,set_label = True):
    if label == "dirty" or label == "short" or label == "shorter":
        color = "maroon"
    elif label == "partlydirty" or label == "long":
        color = "lightcoral"
    elif label == "short_2":
        color = "navy"
    else:
        color = "lightseagreen"

    if fig is None or axs is None:
        fig, axs = plt.subplots(6, 1)

    if stop_index == -1:
        stop_index = np.shape(np.transpose(force["larm"]))[1]
        print "stop_index"
        print stop_index



    #line0, = axs[0].plot(mean_filter(np.transpose(force["larm"])[0][start_index:stop_index],window),color)
    line0, = axs[0].plot(np.transpose(force["larm"])[0][start_index:stop_index],color)
    line1, = axs[1].plot(np.transpose(force["larm"])[1][start_index:stop_index],color)
    line2, = axs[2].plot(np.transpose(force["larm"])[2][start_index:stop_index],color)
    

    line3, = axs[3].plot(np.transpose(force["rarm"])[0][start_index:stop_index],color)
    line4, = axs[4].plot(np.transpose(force["rarm"])[1][start_index:stop_index],color)
    line5, = axs[5].plot(np.transpose(force["rarm"])[2][start_index:stop_index],color)

    if plot_radial_force:
        line6, = axs[6].plot(np.transpose(force["larm"])[3][start_index:stop_index],color)
        line7, = axs[7].plot(np.transpose(force["rarm"])[3][start_index:stop_index],color)
        axs[6].set_ylabel("Fr larm")
        axs[7].set_ylabel("Fr rarm")
        axs[6].legend()
        axs[7].legend()

    if set_label:
        line0.set_label(label)
        line1.set_label(label)
        line2.set_label(label)
        line3.set_label(label)
        line4.set_label(label)
        line5.set_label(label)
        if plot_radial_force:
            line6.set_label(label)
            line7.set_label(label)

    axs[0].set_ylabel("Fx larm")
    axs[1].set_ylabel("Fy larm")
    axs[2].set_ylabel("Fz larm")
    axs[3].set_ylabel("Fx rarm")
    axs[4].set_ylabel("Fy rarm")
    axs[5].set_ylabel("Fz rarm")

    axs[0].legend()
    axs[1].legend()
    axs[2].legend()
    axs[3].legend()
    axs[4].legend()
    axs[5].legend()


def plot_force(ts,force,label,start_index = 0,stop_index = -1,fig=None,axs=None,set_label = True):
    if label == "dirty" or label == "short" or label == "shorter" or label == "short_old":
        color = "maroon"
    elif label == "partlydirty" or label == "long" or label == "long_old":
        color = "lightcoral"
    elif label == "short_2" or label=="short_3" or label == "movement_exp":
        color = "navy"
    else:
        color = "lightseagreen"

    if fig is None or axs is None:
        fig, axs = plt.subplots(6, 1)

    if stop_index == -1:
        stop_index = np.shape(np.transpose(force["larm"]))[1]
        print "stop_index"
        print stop_index

    print "in plot shapes x y "
    print np.shape(force["larm"])
    print np.shape(np.transpose(force["larm"])[0][start_index:stop_index])
    print np.shape(ts)

    #line0, = axs[0].plot(mean_filter(np.transpose(force["larm"])[0][start_index:stop_index],window),color)
    line0, = axs[0].plot(ts,np.transpose(force["larm"])[0][start_index:stop_index],color)
    line1, = axs[1].plot(ts,np.transpose(force["larm"])[1][start_index:stop_index],color)
    line2, = axs[2].plot(ts,np.transpose(force["larm"])[2][start_index:stop_index],color)
    

    line3, = axs[3].plot(ts,np.transpose(force["rarm"])[0][start_index:stop_index],color)
    line4, = axs[4].plot(ts,np.transpose(force["rarm"])[1][start_index:stop_index],color)
    line5, = axs[5].plot(ts,np.transpose(force["rarm"])[2][start_index:stop_index],color)

    if plot_radial_force:
        line6, = axs[6].plot(ts,np.transpose(force["larm"])[3][start_index:stop_index],color)
        line7, = axs[7].plot(ts,np.transpose(force["rarm"])[3][start_index:stop_index],color)
        axs[6].set_ylabel("Fr larm")
        axs[7].set_ylabel("Fr rarm")
        axs[6].legend()
        axs[7].legend()

    if set_label:
        line0.set_label(label)
        line1.set_label(label)
        line2.set_label(label)
        line3.set_label(label)
        line4.set_label(label)
        line5.set_label(label)
        if plot_radial_force:
            line6.set_label(label)
            line7.set_label(label)

    axs[0].set_ylabel("Fx larm")
    axs[1].set_ylabel("Fy larm")
    axs[2].set_ylabel("Fz larm")
    axs[3].set_ylabel("Fx rarm")
    axs[4].set_ylabel("Fy rarm")
    axs[5].set_ylabel("Fz rarm")

    axs[0].legend()
    axs[1].legend()
    axs[2].legend()
    axs[3].legend()
    axs[4].legend()
    axs[5].legend()

def plot_force_mean_filter(ts,force,label,start_index = 0,stop_index = -1,fig=None,axs=None,set_label = True):
    if label == "dirty" or label == "short" or label == "shorter":
        color = "maroon"
    elif label == "partlydirty" or label == "long":
        color = "lightcoral"
    elif label == "short_2":
        color = "navy"
    else:
        color = "lightseagreen"

    if fig is None or axs is None:
        fig, axs = plt.subplots(6, 1)

    print np.shape(force["larm"])

    #line0, = axs[0].plot(mean_filter(np.transpose(force["larm"])[0][start_index:stop_index],window),color)
    line0, = axs[0].plot(mean_filter(np.transpose(force["larm"])[0][start_index:stop_index],window),color)
    line1, = axs[1].plot(mean_filter(np.transpose(force["larm"])[1][start_index:stop_index],window),color)
    line2, = axs[2].plot(mean_filter(np.transpose(force["larm"])[2][start_index:stop_index],window),color)
    

    line3, = axs[3].plot(mean_filter(np.transpose(force["rarm"])[0][start_index:stop_index],window),color)
    line4, = axs[4].plot(mean_filter(np.transpose(force["rarm"])[1][start_index:stop_index],window),color)
    line5, = axs[5].plot(mean_filter(np.transpose(force["rarm"])[2][start_index:stop_index],window),color)

    if plot_radial_force:
        line6, = axs[6].plot(mean_filter(np.transpose(force["larm"])[3][start_index:stop_index],window),color)
        line7, = axs[7].plot(mean_filter(np.transpose(force["rarm"])[3][start_index:stop_index],window),color)
        axs[6].set_ylabel("Fr larm")
        axs[7].set_ylabel("Fr rarm")
        axs[6].legend()
        axs[7].legend()

    if set_label:
        line0.set_label(label)
        line1.set_label(label)
        line2.set_label(label)
        line3.set_label(label)
        line4.set_label(label)
        line5.set_label(label)
        if plot_radial_force:
            line6.set_label(label)
            line7.set_label(label)

    axs[0].set_ylabel("Fx larm")
    axs[1].set_ylabel("Fy larm")
    axs[2].set_ylabel("Fz larm")
    axs[3].set_ylabel("Fx rarm")
    axs[4].set_ylabel("Fy rarm")
    axs[5].set_ylabel("Fz rarm")

    axs[0].legend()
    axs[1].legend()
    axs[2].legend()
    axs[3].legend()
    axs[4].legend()
    axs[5].legend()

def plot_force_strided(force,label,start_index = 0,stop_index = -1,fig=None,axs=None,set_label = True):
    if label == "dirty" or label == "short" or label == "shorter":
        color = "maroon"
    elif label == "partlydirty" or label == "long":
        color = "lightcoral"
    elif label == "short_2":
        color = "navy"
    else:
        color = "lightseagreen"

    if fig is None or axs is None:
        fig, axs = plt.subplots(6, 1)

    print np.shape(force["larm"])

    line0, = axs[0].plot(mean_filter_strided(np.transpose(force["larm"])[0][start_index:stop_index],window),color)
    line1, = axs[1].plot(mean_filter_strided(np.transpose(force["larm"])[1][start_index:stop_index],window),color)
    line2, = axs[2].plot(mean_filter_strided(np.transpose(force["larm"])[2][start_index:stop_index],window),color)
    

    line3, = axs[3].plot(mean_filter_strided(np.transpose(force["rarm"])[0][start_index:stop_index],window),color)
    line4, = axs[4].plot(mean_filter_strided(np.transpose(force["rarm"])[1][start_index:stop_index],window),color)
    line5, = axs[5].plot(mean_filter_strided(np.transpose(force["rarm"])[2][start_index:stop_index],window),color)

    if plot_radial_force:
        line6, = axs[6].plot(mean_filter_strided(np.transpose(force["larm"])[3][start_index:stop_index],window),color)
        line7, = axs[7].plot(mean_filter_strided(np.transpose(force["rarm"])[3][start_index:stop_index],window),color)
        axs[6].set_ylabel("Fr larm")
        axs[7].set_ylabel("Fr rarm")
        axs[6].legend()
        axs[7].legend()

    if set_label:
        line0.set_label(label)
        line1.set_label(label)
        line2.set_label(label)
        line3.set_label(label)
        line4.set_label(label)
        line5.set_label(label)
        if plot_radial_force:
            line6.set_label(label)
            line7.set_label(label)

    axs[0].set_ylabel("Fx larm")
    axs[1].set_ylabel("Fy larm")
    axs[2].set_ylabel("Fz larm")
    axs[3].set_ylabel("Fx rarm")
    axs[4].set_ylabel("Fy rarm")
    axs[5].set_ylabel("Fz rarm")

    axs[0].legend()
    axs[1].legend()
    axs[2].legend()
    axs[3].legend()
    axs[4].legend()
    axs[5].legend()
    
def plot_force_debug_compare_force(force,label,start_index = 0,stop_index = -1,fig=None,axs=None,set_label = True):
    if label == "dirty" or label == "short" or label == "shorter":
        color = "maroon"
    elif label == "partlydirty" or label == "long":
        color = "lightcoral"
    else:
        color = "lightseagreen"

    if fig is None or axs is None:
        fig, axs = plt.subplots(6, 1)

    line0, = axs[0].plot(mean_filter_strided(np.transpose(force["larm"])[0][start_index:stop_index],window),color)
    line1, = axs[1].plot(mean_filter_strided(np.transpose(force["larm"])[2][start_index:stop_index],window),color)


    if set_label:
        line1.set_label(label)

    axs[1].set_ylabel("Fyz")
    axs[1].legend()


def plot_force_color_map(ts,force,label,start_index = 0,stop_index = -1,fig=None,axs=None,set_label = True, i=0,only_z=False):
    print i
    #viridis = cm.get_cmap('viridis', 12)
    #viridis = cm.get_cmap('Blues', 12)
    #viridis = cm.get_cmap('PiYG', 12)
    viridis = cm.get_cmap('RdYlGn', 12)
    #print viridis
    #print viridis.colors
    #print viridis(1.0/13*i)
    #color = viridis(1.0/13*i)
    #zero is read, 1 is green, 0.5 is yellow
    #color = viridis(0.5)
    color = viridis(i)
    if i == 0:
        color = "darksalmon"
    #print color

    if fig is None or axs is None:
        fig, axs = plt.subplots(6, 1)

    if stop_index == -1:
        stop_index = np.shape(np.transpose(force["larm"]))[1]
        print "stop_index"
        print stop_index

    #print "in plot shapes x y "
    #print np.shape(force["larm"])
    #print np.shape(np.transpose(force["larm"])[0][start_index:stop_index])
    #print np.shape(ts)

    #line0, = axs[0].plot(mean_filter(np.transpose(force["larm"])[0][start_index:stop_index],window),color)
    if only_z:
        line0, = axs[0].plot(ts,np.transpose(force["larm"])[2][start_index:stop_index],color=color)
        line1, = axs[1].plot(ts,np.transpose(force["rarm"])[2][start_index:stop_index],color=color)

        if set_label:
            line0.set_label(label)
            line1.set_label(label)

        axs[0].set_ylabel("Fz larm")
        axs[1].set_ylabel("Fz rarm")
        axs[0].legend()
        axs[1].legend()

    else:
        line0, = axs[0].plot(ts,np.transpose(force["larm"])[0][start_index:stop_index],color=color)
        line1, = axs[1].plot(ts,np.transpose(force["larm"])[1][start_index:stop_index],color=color)
        line2, = axs[2].plot(ts,np.transpose(force["larm"])[2][start_index:stop_index],color=color)
        

        line3, = axs[3].plot(ts,np.transpose(force["rarm"])[0][start_index:stop_index],color=color)
        line4, = axs[4].plot(ts,np.transpose(force["rarm"])[1][start_index:stop_index],color=color)
        line5, = axs[5].plot(ts,np.transpose(force["rarm"])[2][start_index:stop_index],color=color)

        if plot_radial_force:
            line6, = axs[6].plot(ts,np.transpose(force["larm"])[3][start_index:stop_index],color=color)
            line7, = axs[7].plot(ts,np.transpose(force["rarm"])[3][start_index:stop_index],color=color)
            axs[6].set_ylabel("Fr larm")
            axs[7].set_ylabel("Fr rarm")
            axs[6].legend()
            axs[7].legend()

        if set_label:
            line0.set_label(label)
            line1.set_label(label)
            line2.set_label(label)
            line3.set_label(label)
            line4.set_label(label)
            line5.set_label(label)
            if plot_radial_force:
                line6.set_label(label)
                line7.set_label(label)

        axs[0].set_ylabel("Fx larm")
        axs[1].set_ylabel("Fy larm")
        axs[2].set_ylabel("Fz larm")
        axs[3].set_ylabel("Fx rarm")
        axs[4].set_ylabel("Fy rarm")
        axs[5].set_ylabel("Fz rarm")

        axs[0].legend()
        axs[1].legend()
        axs[2].legend()
        axs[3].legend()
        axs[4].legend()
        axs[5].legend()

if __name__ == "__main__":
    main()