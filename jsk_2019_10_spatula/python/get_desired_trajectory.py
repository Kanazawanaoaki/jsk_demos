import rosbag
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import butter, lfilter, freqz, filtfilt
from matplotlib import interactive
import os

import h5py


def main(): 
    #directory = "/home/leus/bag_whole_sequence"
    directory = "/home/leus/bag_vision"
    bagfile_vision = "%s/2019-11-08-19-18-47.bag" % directory
    bagfile_grey_down_foam1 = "%s/2019-11-04-21-50-47.bag" % directory
    bagfile_grey_up_foam1 = "%s/2019-11-04-21-54-33.bag" % directory
    bagfile_green_foam = "%s/2019-11-04-21-58-16.bag" % directory
    bagfile_grey_down_foam2 = "%s/2019-11-04-22-02-59.bag" % directory
    bagfile_grey_up_extreme_foam = "%s/2019-11-04-22-09-25.bag" % directory
    bagfile_grey_up_foam2 = "%s/2019-11-04-22-14-16.bag" % directory
    bagfile_grey_down_nofoam = "%s/2019-11-04-22-24-39.bag" % directory
    bagfile_green_nofoam = "%s/2019-11-04-22-28-32.bag" % directory
    data_list = []

    data_kind=["/r_arm_controller/state","actual"] #actual,desired, error
    #joint = "r_forearm_roll_joint"
    joint = "r_shoulder_pan_joint"
    plot = True
    topic = "vision"


    """
    for bag in os.listdir(directory):
        bag_spatula_and_bowl = "%s/%s" % (directory,bag)
        print bag

        #bag_spatula_and_bowl = '/home/leus/force_test_bag/push_robot_2019-10-24-14-37-35.bag'


        #change the joint here to the joint you want to plot
        data_kind=["/r_arm_controller/state","error"] #actual,desired, error
        joint = "r_forearm_roll_joint"
        #joint = "r_shoulder_pan_joint"
        #data_kind=["/l_arm_controller/state","desired"]
        #joint = "l_elbow_flex_joint"

        #decide if u want to plot the data
        plot = True

        d = data_analysis(joint,bag_spatula_and_bowl,data_kind=data_kind)
        d.extract_bag_data()
        d.split_data()
        d.color = 'firebrick'
        avg_min_max_aray = compute_desired_trajectory(d)
        d.avg_position = avg_min_max_aray[0]
        d.min_position = avg_min_max_aray[1]
        d.max_position = avg_min_max_aray[2]


        data_list.append(d)
        #d_spatula_and_bowl.save_trajectory_to_h5(directory,"touching")
    """
    if topic == "vision":
        d_vision = data_analysis(joint,bagfile_vision,data_kind=data_kind)
        d_vision.extract_bag_data()
        d_vision.split_data()
        d_vision.color = 'firebrick'
        #d_vision.compute_desired_trajectory()
    

    if topic == "haptic":
        d_grey_down_foam1 = data_analysis(joint,bagfile_grey_down_foam1,data_kind=data_kind)
        d_grey_down_foam1.extract_bag_data()
        d_grey_down_foam1.split_data()
        d_grey_down_foam1.color = 'firebrick'
        d_grey_down_foam1.compute_desired_trajectory()
        #save_trajectory_to_h5(d,directory,"touching")
        #d.avg_position = avg_min_max_array[0]
        #d.min_position = avg_min_max_array[1]
        #d.max_position = avg_min_max_array[2]

        d_grey_up_foam1 = data_analysis(joint,bagfile_grey_up_foam1,data_kind=data_kind)
        d_grey_up_foam1.extract_bag_data()
        d_grey_up_foam1.split_data()
        d_grey_up_foam1.color = 'darkcyan'
        d_grey_up_foam1.compute_desired_trajectory()
        #save_trajectory_to_h5(d,directory,"touching")
        #d.avg_position = avg_min_max_array[0]
        #d.min_position = avg_min_max_array[1]
        #d.max_position = avg_min_max_array[2]

        d_grey_down_foam2 = data_analysis(joint,bagfile_grey_down_foam2,data_kind=data_kind)
        d_grey_down_foam2.extract_bag_data()
        d_grey_down_foam2.split_data()
        d_grey_down_foam2.color = 'darksalmon'
        d_grey_down_foam2.compute_desired_trajectory()
        #save_trajectory_to_h5(d,directory,"touching")
        #d.avg_position = avg_min_max_array[0]
        #d.min_position = avg_min_max_array[1]
        #d.max_position = avg_min_max_array[2]

        d_grey_up_foam2 = data_analysis(joint,bagfile_grey_up_foam2,data_kind=data_kind)
        d_grey_up_foam2.extract_bag_data()
        d_grey_up_foam2.split_data()
        d_grey_up_foam2.color = 'paleturquoise'
        d_grey_up_foam2.compute_desired_trajectory()
        #save_trajectory_to_h5(d,directory,"touching")
        #d.avg_position = avg_min_max_array[0]
        #d.min_position = avg_min_max_array[1]
        #d.max_position = avg_min_max_array[2]

        #d_grey_up_extreme_foam = data_analysis(joint,bagfile_grey_up_extreme_foam,data_kind=data_kind)
        #d_grey_up_extreme_foam.extract_bag_data()
        #d_grey_up_extreme_foam.split_data()
        #d_grey_up_extreme_foam.color = 'lightseagreen'
        #d_grey_up_extreme_foam.compute_desired_trajectory()
        #save_trajectory_to_h5(d,directory,"touching")
        #d.avg_position = avg_min_max_array[0]
        #d.min_position = avg_min_max_array[1]
        #d.max_position = avg_min_max_array[2]

        
        d_green_foam = data_analysis(joint,bagfile_green_foam,data_kind=data_kind)
        d_green_foam.extract_bag_data()
        d_green_foam.split_data()
        d_green_foam.color = 'olivedrab'
        d_green_foam.compute_desired_trajectory()
        #save_trajectory_to_h5(d,directory,"touching")
        #d.avg_position = avg_min_max_array[0]
        #d.min_position = avg_min_max_array[1]
        #d.max_position = avg_min_max_array[2]

        d_green_nofoam = data_analysis(joint,bagfile_green_nofoam,data_kind=data_kind)
        d_green_nofoam.extract_bag_data()
        d_green_nofoam.split_data()
        d_green_nofoam.color = 'chartreuse'
        d_green_nofoam.compute_desired_trajectory()
        #save_trajectory_to_h5(d,directory,"touching")
        #d.avg_position = avg_min_max_array[0]
        #d.min_position = avg_min_max_array[1]
        #d.max_position = avg_min_max_array[2]

        d_grey_down_nofoam = data_analysis(joint,bagfile_grey_down_nofoam,data_kind=data_kind)
        d_grey_down_nofoam.extract_bag_data()
        d_grey_down_nofoam.split_data()
        d_grey_down_nofoam.color = 'yellow'
        d_grey_down_nofoam.compute_desired_trajectory()
        #save_trajectory_to_h5(d,directory,"touching")
        #d.avg_position = avg_min_max_array[0]
        #d.min_position = avg_min_max_array[1]
        #d.max_position = avg_min_max_array[2]

    """
    d_no_bowl = data_analysis(joint,bagfile_no_bowl,data_kind=data_kind)
    d_no_bowl.extract_bag_data()
    d_no_bowl.split_data()
    d_no_bowl.color = 'seagreen'
    d_no_bowl.compute_desired_trajectory()#(d_no_bowl)

    
    #d_no_bowl.avg_position = avg_min_max_array[0]
    #d_no_bowl.min_position = avg_min_max_array[1]
    #d_no_bowl.max_position = avg_min_max_array[2]
    #save_trajectory_to_h5(d_no_bowl,directory,"not_touching")


    d_30 = data_analysis(joint,bagfile_30,data_kind=data_kind)
    d_30.extract_bag_data()
    d_30.split_data()
    d_30.color = 'mediumspringgreen'
    d_30.compute_desired_trajectory()#(d_30)

    d_50 = data_analysis(joint,bagfile_50,data_kind=data_kind)
    d_50.extract_bag_data()
    d_50.split_data()
    d_50.color = 'lightseagreen'
    d_50.compute_desired_trajectory()#(d_50)

    d_10 = data_analysis(joint,bagfile_10,data_kind=data_kind)
    d_10.extract_bag_data()
    d_10.split_data()
    d_10.color = 'chartreuse'
    d_10.compute_desired_trajectory()#(d_20)
    
    plot_filtered_unfiltered([d,d_no_bowl,d_10,d_30,d_50],interactive_plot=True)
    """


    """
    d_no_spatula = data_analysis(joint,bag_no_spatula,data_kind=data_kind)
    d_no_spatula.extract_bag_data()
    d_no_spatula.split_data()
    d_no_spatula.color = 'navy'#'darkgreen'
    avg_min_max_aray = compute_desired_trajectory(d_no_bowl)
    d_no_spatula.avg_position = avg_min_max_aray[0]
    d_no_spatula.min_position = avg_min_max_aray[1]
    d_no_spatula.max_position = avg_min_max_aray[2]
    save_trajectory_to_h5(d_no_spatula,directory,"not_touching_no_spatula")
    


    d_5up = data_analysis(joint,bag_5up, bagtype = "5_up",data_kind=data_kind)
    d_5up.extract_bag_data()
    d_5up.split_data()
    d_5up.color = 'darksalmon'

    d_15up = data_analysis(joint,bag_15up, bagtype = "15_up",data_kind=data_kind)
    d_15up.extract_bag_data()
    d_15up.split_data()
    d_15up.color = 'sienna'
    """
        


    if plot:
        if not data_list:
            if joint[0] == "l":
                print "you picked a joint from left arm, plotting spatula_and_bowl and no_spatula"
                data_list = [d_spatula_and_bowl,d_no_spatula,d_no_bowl]
            elif joint[0] == "r":
                print "you picked a joint from right arm, plotting spatula_and_bowl and no_bowl"
                if topic == "haptic":
                    data_list = [d_grey_down_foam1,d_grey_up_foam1,d_grey_down_foam2,d_grey_up_foam2,d_green_nofoam,d_green_foam,d_grey_down_nofoam]#,d_10,d_30,d_50,d_no_bowl]#d_no_spatula,[d_spatula_and_bowl,d_no_bowl]#[d_15up,d_spatula_and_bowl,d_no_bowl,d_5up]
                elif topic == "vision":
                    data_list = [d_vision];
            else:
                print "you picked a joint that is not from either arm plotting all three experiments"
                data_list = [d_spatula_and_bowl,d_spatula_and_bowl,d_no_spatula,d_no_bowl,d_grey_up_extreme_foam]#[d_spatula_and_bowl,d_no_spatula,d_no_bowl,d_5up]

        plot_data(data_list, show_av2=True, interactive_plot=False) 
        #eg. add argument cutoff_f = 10, to apply lowpass filter with cutoff frequency 10 to the effort
        #add interactive_plot=True to make the programm run further without having to close the plot
        #plot_filtered_unfiltered(d_spatula_and_bowl, cutoff_f=5)


class data_analysis:

    def __init__(self,joint_name,path,debug_mode=False,bagtype=None,data_kind=["/r_arm_controller/state","desired"]):
        self.bag = rosbag.Bag(path)
        print self.bag
        self.joint_name = joint_name
        self.debug_mode = debug_mode
        self.bag_type = bagtype
        self.data_kind = data_kind
        self.start_timestamps = []
        self.stop_timestamps = []
        self.data_timestamps = []
        self.tf = []
        self.effort = dict()
        self.effort["desired"] = []
        self.effort["actual"] = []
        self.effort["error"] = []
        self.position = dict()
        self.position["desired"] = []
        self.position["actual"] = []
        self.position["error"] = []
        self.velocity = dict()
        self.velocity["desired"] = []
        self.velocity["actual"] = []
        self.velocity["error"] = []
        self.split_indices = []
        self.split_indices_start = []
        self.split_indices_stop = []
        self.av2_indices = []
        self.simulation = False #if the data comes form simulation there is no effort signal abailable
        self.plot_whole_sequence = False
        self.plot_max_min_avg = False
        self.x_pos = []


    def extract_bag_data(self):
        #self.effort = []
        #self.position = []
        #self.velocity = []
        #self.split_indices = []
        #self.split_indices_start = []
        #self.split_indices_stop = []
        #self.av2_indices = []
        first = True

        #when the robot starts scraping it is at av_1, when it lifts the spatula off the bowl it is at position av_2
        #in order to split the bag file that contains 40 iterations, this angle vector is 
        #compared to the angle vector of the bag file, if it the difference is small, the file is split
        self.av_1 = (2*np.pi/360) * np.array([49.9331,62.6833,33.1418,127.946,-117.444,-7.41574,-5.72958,51.833,-16.9966,-9.03369,-111.73,-116.714,-76.193,-57.7095,266.18,3.0727,-21.2682])
        self.av_2 = (2*np.pi/360) * np.array([49.9331,62.3888,32.6716,129.774,-117.502,-7.41574,-5.72958,51.833,-29.1714,-9.19364,-117.398,-118.456,-81.5623,-50.4353,263.348,3.0727,-21.2682])
        if self.bag_type is "5_up":
            self.av_1 = (2*np.pi/360) * np.array([49.9331,62.1038,31.4599,129.388,-117.925,-17.5744,-5.72958,61.2193,-16.9966,-9.03369,-111.73,-116.714,-76.193,-57.7095,266.18,3.0727,-21.2682])
            self.av_2 = (2*np.pi/360) * np.array([49.9331,62.1038,31.4599,129.388,-117.925,-17.5744,-5.72958,61.2193,-29.1714,-9.19364,-117.398,-118.456,-81.5623,-50.4353,263.348,3.0727,-21.2682])
        elif self.bag_type is "15_up":
            self.av_1 = (2*np.pi/360) * np.array([49.9331,60.6407,29.3418,129.618,-119.459,-42.6544,-5.72958,84.7396,-16.9966,-9.03369,-111.73,-116.714,-76.193,-57.7095,266.18,3.0727,-21.2682])
            self.av_2 = (2*np.pi/360) * np.array([49.9331,60.6407,29.3418,129.618,-119.459,-42.6544,-5.72958,84.7396,-29.0716,-9.25665,-86.0776,-118.804,-76.2328,-66.8658,270.291,3.0727,-21.2682])

        #names of 17 jointpositions in av_1 and av_2
        self.cmd_joints = ["torso_lift_joint", "l_shoulder_pan_joint","l_shoulder_lift_joint","l_upper_arm_roll_joint","l_elbow_flex_joint","l_forearm_roll_joint","l_wrist_flex_joint","l_wrist_roll_joint","r_shoulder_pan_joint","r_shoulder_lift_joint","r_upper_arm_roll_joint","r_elbow_flex_joint","r_forearm_roll_joint","r_wrist_flex_joint","r_wrist_roll_joint","head_pan_joint","head_tilt_joint"]
        
        n_split = 0
        if self.debug_mode:
            max_diff = 0
            min_diff = float('inf')

        split_window = dict()
        av2_window = dict()
        
        i = 0
        k = 0
        first_tf = True

        for topic, msg, t in self.bag.read_messages(''):

            if topic == "/action_r_arm":
                split_action = msg.data.split("_")
                if split_action[0] == "av2wall" and split_action[1] == "0":
                    self.start_timestamps.append(t)
                elif split_action[0] == "av4wall" and split_action[1] == "0":
                    self.stop_timestamps.append(t)

            if topic == "/tf":
                #extract the transformations of the right arm
                if False:#True:
                    self.tf.append(msg.transforms)
                    print "------------"
                    for t in msg.transforms:
                        print t.header.frame_id
                    print len(msg.transforms)
                    print type(msg.transforms[0])
                    translation =  [msg.transforms[0].transform.translation.x,msg.transforms[0].transform.translation.y,msg.transforms[0].transform.translation.z]
                    print translation
                    rotation =  [msg.transforms[0].transform.rotation.x,msg.transforms[0].transform.rotation.y,msg.transforms[0].transform.rotation.z]
                    print rotation
                    child_frame_id = msg.transforms[0].child_frame_id
                    frame_id = msg.transforms[0].header.frame_id
                    first_tf = False


            if topic != self.data_kind[0]:
                continue #looking into "/r_arm_controller/state" only

            self.data_timestamps.append(t)

            self.effort["desired"].append(msg.desired.effort)
            self.effort["error"].append(msg.error.effort)
            self.effort["actual"].append(msg.actual.effort)

            self.position["desired"].append(msg.desired.positions)
            self.position["error"].append(msg.error.positions)
            self.position["actual"].append(msg.actual.positions)

            self.velocity["desired"].append(msg.desired.velocities)
            self.velocity["error"].append(msg.error.velocities)
            self.velocity["actual"].append(msg.actual.velocities)
            #print np.shape(msg.desired.effort)
            #print np.shape(msg.error.effort)
            #print np.shape(msg.actual.effort)
            
            if self.data_kind[1] is "desired":
                #self.effort.append(msg.desired.effort)
                #self.position.append(msg.desired.positions)
                #self.velocity.append(msg.desired.velocities)
                pass
            elif self.data_kind[1] is "error":
                #self.effort.append(msg.error.effort)
                #self.position.append(msg.error.positions)
                #self.velocity.append(msg.error.velocities)
                pass
            elif self.data_kind[1] is "actual":
                #self.effort.append(msg.actual.effort)
                #self.position.append(msg.actual.positions)
                #self.velocity.append(msg.actual.velocities)
                pass
            else:
                "please choose either 'desired' or 'error' or 'actual' as data_kind[1]!"
            
            
            if first:
                self.name = msg.joint_names

                r_arm_controller_indices = []
                for joint in self.name:
                    r_arm_controller_indices.append(self.cmd_joints.index(joint))
                first = False
            pos_array = np.array(msg.desired.positions)


            diff_limit = 1.1 
            if np.sum(np.abs((pos_array-self.av_1[r_arm_controller_indices])/self.av_1[r_arm_controller_indices])) < diff_limit:
                n_split = n_split + 1 
                split_window[np.sum(np.abs((pos_array-self.av_1[r_arm_controller_indices])/self.av_1[r_arm_controller_indices]))] = i

            elif split_window:
                self.split_indices.append(split_window[np.min(split_window.keys())])
                split_window = dict()
            i = i+1

        if self.debug_mode:
            print "n_split"
            print n_split
            print "max difference"
            print max_diff
            print "min difference"
            print min_diff

        self.bag.close();
        #KO
        print self.data_timestamps
        self.effort["actual"] = np.array(self.effort["actual"])
        self.effort["error"] = np.array(self.effort["error"])
        self.effort["desired"] = np.array(self.effort["desired"])
        self.position["actual"] = np.array(self.position["actual"])
        self.position["error"] = np.array(self.position["error"])
        self.position["desired"] = np.array(self.position["desired"])
        self.velocity["actual"] = np.array(self.velocity["actual"])
        self.velocity["error"] = np.array(self.velocity["error"])
        self.velocity["desired"] = np.array(self.velocity["desired"])
        self.ind_joint = self.name.index(self.joint_name)

    def split_data(self):

        self.split_indices = []
        for index in self.start_timestamps:
            self.split_indices_start.append(np.argmin(abs(np.array(self.data_timestamps) - index)))

        for index in self.stop_timestamps:
            self.split_indices_stop.append(np.argmin(abs(np.array(self.data_timestamps) - index)))

        self.n_exp = len(self.split_indices_start)
        if self.plot_whole_sequence:
            self.n_exp = self.n_exp - 1 #do not plot the last one as u dont know where to stop

        position_shape = np.shape(self.position["actual"])
        n_joint = position_shape[1]
        tmp_indices = self.split_indices[0:-1]
        #tmp_indices = self.split_indices_start[0:-1]
        tmp_indices.insert(0,0)

        if self.plot_whole_sequence:
            self.plot_length = np.array(self.split_indices_start[1::]) - np.array(self.split_indices_start[0:-1])
            n_time = np.max(self.plot_length)
        else:
            self.plot_length = np.array(self.split_indices_stop) - np.array(self.split_indices_start)
            n_time = np.max(np.array(self.split_indices_stop) - np.array(self.split_indices_start))
        self.split_effort = np.array(np.zeros([self.n_exp,n_time,n_joint]))
        self.split_velocity = np.array(np.zeros([self.n_exp,n_time,n_joint]))
        self.split_position = np.array(np.zeros([self.n_exp,n_time,n_joint]))
        i = 0

        if self.plot_whole_sequence:
            old_ind = self.split_indices_start[0]
            for split_ind in self.split_indices_start:
                if split_ind is old_ind:
                    continue
                self.split_effort[i,0:split_ind-old_ind,:] = self.effort[old_ind:split_ind,:]
                self.split_velocity[i,0:split_ind-old_ind,:] = self.velocity[old_ind:split_ind,:]
                self.split_position[i,0:split_ind-old_ind,:] = self.position[old_ind:split_ind,:]
                old_ind = split_ind
                i = i+1
        else:
            for split_ind in self.split_indices_stop:
                old_ind = self.split_indices_start[i]
                diff_ind = split_ind - old_ind
                if not self.simulation:
                    #print type(self.effort)
                    #print type(self.effort["%s" % self.data_kind[1]])
                    #print "%s" % self.data_kind[1]
                    #print np.shape(self.effort["%s" % self.data_kind[1]])
                    self.split_effort[i,0:split_ind-old_ind,:] = self.effort["%s" % self.data_kind[1]][old_ind:split_ind,:]
                self.split_velocity[i,0:split_ind-old_ind,:] = self.velocity["%s" % self.data_kind[1]][old_ind:split_ind,:]
                self.split_position[i,0:split_ind-old_ind,:] = self.position["%s" % self.data_kind[1]][old_ind:split_ind,:]
                i = i+1
        


    def compute_desired_trajectory(self):
        length = np.min(self.plot_length)
        #avg = np.mean(data.split_position[2::,0:length,data.ind_joint],0)
        #min_sequence = np.min(data.split_position[2::,0:length,data.ind_joint],0)
        #max_sequence = np.max(data.split_position[2::,0:length,data.ind_joint],0)

        self.avg_position = np.mean(self.split_position[0::,0:length,self.ind_joint],0)
        self.min_position = np.min(self.split_position[0::,0:length,self.ind_joint],0)
        self.max_position = np.max(self.split_position[0::,0:length,self.ind_joint],0)

        if not self.simulation:
            self.avg_effort = np.mean(self.split_effort[0::,0:length,self.ind_joint],0)
            self.min_effort = np.min(self.split_effort[0::,0:length,self.ind_joint],0)
            self.max_effort = np.max(self.split_effort[0::,0:length,self.ind_joint],0)


    #return [avg,min_sequence,max_sequence]
    """
    for i in range(start_ind,data.n_exp):
        length = data.plot_length[i]
        avg[0:length] = avg[0:length] + data.split_effort[i,0:length,data.ind_joint]
    avg = avg/data.n_exp
    """

    def save_trajectory_to_h5(self,directory,exp_type):
        f = h5py.File("%s/desired_trajectory.hdf5" % (directory))
        f.create_dataset("%s/avg_position" % exp_type, data = self.avg_position)
        f.create_dataset("%s/max_position" % exp_type, data = self.max_position)
        f.create_dataset("%s/min_position" % exp_type, data = self.min_position)

        if not self.simulation:
            f.create_dataset("%s/avg_effort" % exp_type, data = self.avg_effort)
            f.create_dataset("%s/max_effort" % exp_type, data = self.max_effort)
            f.create_dataset("%s/min_effort" % exp_type, data = self.min_effort)
        f.close()

def mean_filter(sequence,window):
    mean_sequence = []
    for i in range(int(np.floor(len(sequence)/window))):
        mean_sequence.append(np.mean(sequence[i*window:(i+1)*window]))
    return mean_sequence 

def numeric_derivative(sequence):
    sequence1 = np.append(sequence,0)
    sequence2 = np.append(0,sequence)
    d_sequence = sequence1 - sequence2
    return d_sequence[0:-1]


def butter_lowpass(cutoff, fs, order=5):
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype='low', analog=False)
    return b, a


def butter_lowpass_filter(data, cutoff, fs, order=5):
    b, a = butter_lowpass(cutoff, fs, order=order)
    y = lfilter(b,a,data)
    return y

def plot_data(data_list,split_plot = True,show_av2=False,cutoff_f=None,order=6,fs=100.3, interactive_plot=False, start_ind = 0):#start_ind was 2
    fig, axs = plt.subplots(7, 1)
    for data in data_list:
        for i in range(start_ind,data.n_exp):
            length = data.plot_length[i]
            t1 = np.array(range(length))
            s1 = data.split_effort[i,0:length,data.ind_joint]
            if cutoff_f is not None:
                s1 = butter_lowpass_filter(s1, cutoff_f, fs, order)
            axs[0].plot(t1, s1, data.color)

        for i in range(start_ind,data.n_exp):
            if False:#i == 3:
                print "navy"
                data.color = "navy"
            if False:#i == 4:
                print "seagreen"
                data.color = "seagreen"
            length = data.plot_length[i]
            t2 = np.array(range(length))
            s2 = data.split_position[i,0:length,data.ind_joint]
            axs[1].plot(t2, s2, data.color)

        for i in range(start_ind,data.n_exp):
            length = data.plot_length[i]
            t3 = np.array(range(length))
            s3 = data.split_velocity[i,0:length,data.ind_joint]
            axs[2].plot(t3, s3, data.color)

        for i in range(start_ind,data.n_exp):
            length = data.plot_length[i]
            t4 = np.array(range(length))
            s4 = numeric_derivative(data.split_velocity[i,0:length,data.ind_joint])
            axs[3].plot(t4, s4, data.color)

        for i in range(start_ind,data.n_exp):
            length = data.plot_length[i]
            t5 = np.array(range(length))
            s5 = numeric_derivative(data.split_position[i,0:length,data.ind_joint])
            axs[4].plot(t5[1::], s5[1::], data.color)

        axs[5].plot(data.position["%s" % data.data_kind[1]][data.split_indices_start[0]:data.split_indices_stop[-1],data.ind_joint],data.color)
        if not data.simulation:
            axs[6].plot(data.effort["%s" % data.data_kind[1]][data.split_indices_start[0]:data.split_indices_stop[-1],data.ind_joint],data.color)

        if data.plot_max_min_avg:
            axs[1].plot(range(len(data.avg_position)),data.avg_position,"black")
            axs[1].plot(range(len(data.min_position)),data.min_position,"gray")
            axs[1].plot(range(len(data.max_position)),data.max_position,"gray")
            if not data.simulation:
                axs[0].plot(range(len(data.avg_effort)),data.avg_effort,"black")
                axs[0].plot(range(len(data.min_effort)),data.min_effort,"gray")
                axs[0].plot(range(len(data.max_effort)),data.max_effort,"gray")

    axs[0].set_xlabel('time',fontsize="small")
    axs[0].set_ylabel('effort_%s' % data.name[data.ind_joint],fontsize="small")
    axs[0].grid(True)  
    axs[1].set_xlabel('time',fontsize="small")
    axs[1].set_ylabel('position_%s' % data.name[data.ind_joint],fontsize="small")
    axs[1].grid(True) 
    axs[2].set_xlabel('time',fontsize="small")
    axs[2].set_ylabel('velocity_%s' % data.name[data.ind_joint],fontsize="small")
    axs[2].grid(True) 
    axs[3].set_xlabel('time',fontsize="small")
    axs[3].set_ylabel('d_velocity_%s' % data.name[data.ind_joint],fontsize="small")
    axs[3].grid(True) 
    axs[4].set_xlabel('time',fontsize="small")
    axs[4].set_ylabel('d_position_%s' % data.name[data.ind_joint],fontsize="small")
    axs[4].grid(True) 
    fig.suptitle("%s --- %s" % (data.data_kind[0],data.data_kind[1]))
    interactive(interactive_plot)
    plt.hold(True)
    plt.show()

def plot_filtered_unfiltered(data_list, cutoff_f=3, order=6, fs=100.3, interactive_plot=False, start_ind = 0):
    fig = plt.figure()
    ax = fig.add_subplot(1,1,1)
    for data in data_list:
        t1 = np.array(range(920))
        for i in range(start_ind,data.n_exp):
            length = data.plot_length[i]
            t1 = np.array(range(length))
            s1 = data.split_effort[i,0:length,data.ind_joint]
            ax.plot(t1, s1, data.color)
        for i in range(start_ind,data.n_exp):   
            length = data.plot_length[i]
            #t2 = np.array(range(length))
            s1 = data.split_effort[i,0:length,data.ind_joint]
            s2 = butter_lowpass_filter(s1, cutoff_f, fs, order)
            #s2 = mean_filter(s1,5)
            t2 = np.array(range(len(s2)))
            ax.plot(t2, s2, "darkcyan")

    fig.tight_layout()
    interactive(interactive_plot)
    plt.show()


if __name__ == "__main__":
    main()