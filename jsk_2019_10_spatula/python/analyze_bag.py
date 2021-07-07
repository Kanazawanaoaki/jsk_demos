import rosbag
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import butter, lfilter, freqz, filtfilt
from matplotlib import interactive

def main(): 
    bag_spatula_and_bowl = '/home/leus/force_test_bag/experiment_with_spatula_and_bowl_2019-10-07-21-45-53.bag'
    bag_no_spatula = '/home/leus/force_test_bag/experiment_without_spatula_2019-10-07-22-00-52.bag'
    bag_no_bowl = '/home/leus/force_test_bag/experiment_without_bowl_2019-10-07-21-51-21.bag'
    bag_5up = '/home/leus/force_test_bag/experiment_with_spatula_and_bowl_5mm_up_2019-10-07-22-21-24.bag'
    bag_15up = '/home/leus/force_test_bag/experiment_with_spatula_and_bowl_15mm_up_2019-10-07-22-32-14.bag'
    
    #bag_spatula_and_bowl = '/home/leus/force_test_bag/experiment_with_spatula_and_bowl_2019-10-23-11-40-14.bag'
    #bag_no_bowl = '/home/leus/force_test_bag/experiment_without_bowl_2019-10-23-11-41-51.bag'

    #change the joint here to the joint you want to plot
    data_kind=["/r_arm_controller/state","error"] #actual,desired, error
    joint = "r_forearm_roll_joint"

    #data_kind=["/l_arm_controller/state","desired"]
    #joint = "l_elbow_flex_joint"

    #decide if u want to plot the data
    plot = True

    d_spatula_and_bowl = data_analysis(joint,bag_spatula_and_bowl,data_kind=data_kind)
    d_spatula_and_bowl.extract_bag_data()
    d_spatula_and_bowl.split_data()
    d_spatula_and_bowl.color = 'firebrick'
 
    #d_no_spatula = data_analysis(joint,bag_no_spatula,data_kind=data_kind)
    #d_no_spatula.extract_bag_data()
    #d_no_spatula.split_data()
    #d_no_spatula.color = 'darkgreen'
    
    d_no_bowl = data_analysis(joint,bag_no_bowl,data_kind=data_kind)
    d_no_bowl.extract_bag_data()
    d_no_bowl.split_data()
    d_no_bowl.color = 'seagreen'

    #d_5up = data_analysis(joint,bag_5up, bagtype = "5_up",data_kind=data_kind)
    #d_5up.extract_bag_data()
    #d_5up.split_data()
    #d_5up.color = 'darksalmon'

    #d_15up = data_analysis(joint,bag_15up, bagtype = "15_up",data_kind=data_kind)
    #d_15up.extract_bag_data()
    #d_15up.split_data()
    #d_15up.color = 'sienna'
    
    
    if plot:
        if joint[0] == "l":
            print "you picked a joint from left arm, plotting spatula_and_bowl and no_spatula"
            data_list = [d_spatula_and_bowl,d_no_spatula,d_5up]
        elif joint[0] == "r":
            print "you picked a joint from right arm, plotting spatula_and_bowl and no_bowl"
            data_list = [d_spatula_and_bowl,d_no_bowl]#[d_15up,d_spatula_and_bowl,d_no_bowl,d_5up]
        else:
            print "you picked a joint that is not from either arm plotting all three experiments"
            data_list = [d_spatula_and_bowl,d_no_spatula,d_no_bowl,d_5up]

        plot_data(data_list, show_av2=True, interactive_plot=True) 
        #eg. add argument cutoff_f = 10, to apply lowpass filter with cutoff frequency 10 to the effort
        #add interactive_plot=True to make the programm run further without having to close the plot
        plot_filtered_unfiltered(d_spatula_and_bowl, cutoff_f=5)


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
        self.split_indices_start = []
        self.split_indices_stop = []
        self.split_indices_start = []
        self.split_indices_stop = []
        self.data_timestamps = []


    def extract_bag_data(self):
        self.effort = []
        self.position = []
        self.velocity = []
        self.split_indices = []
        self.av2_indices = []
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
        
        #print "#############index follows###############"
        #print self.cmd_joints.index("r_wrist_roll_joint")
        n_split = 0
        if self.debug_mode:
            max_diff = 0
            min_diff = float('inf')

        split_window = dict()
        av2_window = dict()
        
        i = 0
        k = 0

        self.start_scraping_published = False 

        for topic, msg, t in self.bag.read_messages(''):

            if self.debug_mode:
                if topic == "/tf" and k < 10: #use this to print first 10 msgs of topic tf
                    print msg
                    k = k+1
                else:
                    continue

            if topic == "/start_scraping":
                if msg.data is True:
                    self.start_timestamps.append(t)
                elif msg.data is False:
                    self.stop_timestamps.append(t)
                self.start_scraping_published = True


            if topic != self.data_kind[0]:
                continue #looking into "/r_arm_controller/state" only

            self.data_timestamps.append(t)

            if self.data_kind[1] is "desired":
                self.effort.append(msg.desired.effort)
                self.position.append(msg.desired.positions)
                self.velocity.append(msg.desired.velocities)
            elif self.data_kind[1] is "error":
                self.effort.append(msg.error.effort)
                self.position.append(msg.error.positions)
                self.velocity.append(msg.error.velocities)
            elif self.data_kind[1] is "actual":
                self.effort.append(msg.actual.effort)
                self.position.append(msg.actual.positions)
                self.velocity.append(msg.actual.velocities)
            else:
                "please choose either 'desired' or 'error' or 'actual' as data_kind[1]!"
            
            if first:
                self.name = msg.joint_names

                r_arm_controller_indices = []
                for joint in self.name:
                    r_arm_controller_indices.append(self.cmd_joints.index(joint))
                first = False
            pos_array = np.array(msg.desired.positions)


            if not self.start_scraping_published:
                diff_limit = 1.1 
                if np.sum(np.abs((pos_array-self.av_1[r_arm_controller_indices])/self.av_1[r_arm_controller_indices])) < diff_limit:
                    n_split = n_split + 1 
                    split_window[np.sum(np.abs((pos_array-self.av_1[r_arm_controller_indices])/self.av_1[r_arm_controller_indices]))] = i

                elif split_window:
                    self.split_indices.append(split_window[np.min(split_window.keys())])
                    split_window = dict()
            """
            if np.sum(np.abs((pos_array[cmd_indices_bag]-self.av_2)/self.av_2)) < diff_limit:
                n_split = n_split + 1 
                av2_window[np.sum(np.abs((pos_array[cmd_indices_bag]-self.av_2)/self.av_2))] = i

            elif av2_window:
                self.av2_indices.append(av2_window[np.min(av2_window.keys())])
                av2_window = dict()
            """
            i = i+1

        """
        if self.bag_type is "15_up":
            self.av2_indices = np.array(self.av2_indices) - np.array(self.split_indices[0:19])#KO
        else:#Hack for 15mm up
            self.av2_indices = np.array(self.av2_indices) - np.array(self.split_indices)
        """

        if self.debug_mode:
            print "n_split"
            print n_split
            print "max difference"
            print max_diff
            print "min difference"
            print min_diff

        self.bag.close();
        self.effort = np.array(self.effort)
        self.position = np.array(self.position)
        self.velocity = np.array(self.velocity)
        self.ind_joint = self.name.index(self.joint_name)

    def split_data(self):
        old_ind = 0

        if self.start_scraping_published:
            for index in self.start_timestamps:
                self.split_indices_start.append(np.argmin(abs(np.array(self.data_timestamps) - index)))
            for index in self.stop_timestamps:
                self.split_indices_stop.append(np.argmin(abs(np.array(self.data_timestamps) - index)))
            self.n_exp = len(self.split_indices_start)
        else:
            self.n_exp = len(self.split_indices)
        effort_shape = np.shape(self.effort)
        n_joint = effort_shape[1]
        tmp_indices = self.split_indices[0:-1]
        tmp_indices.insert(0,0)

        if self.start_scraping_published:
            self.plot_length = np.array(self.split_indices_stop) - np.array(self.split_indices_start)
        else:
            self.plot_length = np.array(self.split_indices) - np.array(tmp_indices)
        print "**********shapes*********"
        print np.shape(self.split_indices)
        print np.shape(tmp_indices)

        if self.start_scraping_published:
            n_time = np.max(np.array(self.split_indices_stop) - np.array(self.split_indices_start))
        else:
            n_time = np.max(np.array(self.split_indices) - np.array(tmp_indices))
        self.split_effort = np.array(np.zeros([self.n_exp,n_time,n_joint]))
        self.split_velocity = np.array(np.zeros([self.n_exp,n_time,n_joint]))
        self.split_position = np.array(np.zeros([self.n_exp,n_time,n_joint]))
        i = 0
        if self.start_scraping_published:
            for split_ind in self.split_indices_stop:
                old_ind = self.split_indices_start[i]
                diff_ind = split_ind - old_ind
                self.split_effort[i,0:split_ind-old_ind,:] = self.effort[old_ind:split_ind,:]
                self.split_velocity[i,0:split_ind-old_ind,:] = self.velocity[old_ind:split_ind,:]
                self.split_position[i,0:split_ind-old_ind,:] = self.position[old_ind:split_ind,:]
                i = i+1
        else:
            for split_ind in self.split_indices:
                diff_ind = split_ind - old_ind
                self.split_effort[i,0:split_ind-old_ind,:] = self.effort[old_ind:split_ind,:]
                self.split_velocity[i,0:split_ind-old_ind,:] = self.velocity[old_ind:split_ind,:]
                self.split_position[i,0:split_ind-old_ind,:] = self.position[old_ind:split_ind,:]
                old_ind = split_ind
                i = i+1


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

def plot_data(data_list,split_plot = True,show_av2=False,cutoff_f=None,order=6,fs=100.3, interactive_plot=False, start_ind = 3):
    fig, axs = plt.subplots(5, 1)
    for data in data_list:
        for i in range(start_ind,data.n_exp):
            length = data.plot_length[i]
            t1 = np.array(range(length))
            s1 = data.split_effort[i,0:length,data.ind_joint]
            if cutoff_f is not None:
                s1 = butter_lowpass_filter(s1, cutoff_f, fs, order)
            axs[0].plot(t1, s1, data.color)

        for i in range(start_ind,data.n_exp):
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

        if show_av2:
            try:
                for av2_idx in data.av2_indices:
                    axs[1].plot(av2_idx,data.av_2[data.cmd_joints.index(data.joint_name)],'%s x' % data.color)
            except:
                print "cannot plot av2, as %s is not part of av2" % data.joint_name

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
    plt.show()

def plot_filtered_unfiltered(data, cutoff_f, order=6, fs=100.3, interactive_plot=False, start_ind = 3):
    t1 = np.array(range(920))
    fig = plt.figure()
    ax = fig.add_subplot(1,1,1)
    for i in range(start_ind,data.n_exp):
        length = data.plot_length[i]
        t1 = np.array(range(length))
        s1 = data.split_effort[i,0:length,data.ind_joint]
        ax.plot(t1, s1, "lightseagreen")
    for i in range(start_ind,data.n_exp):   
        length = data.plot_length[i]
        t2 = np.array(range(length))
        s1 = data.split_effort[i,0:length,data.ind_joint]
        s2 = butter_lowpass_filter(s1, cutoff_f, fs, order)
        ax.plot(t2, s2, "darkcyan")
    fig.tight_layout()
    interactive(interactive_plot)
    plt.show()


if __name__ == "__main__":
    main()