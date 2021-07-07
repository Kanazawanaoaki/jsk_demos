import rosbag
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import butter, lfilter, freqz, filtfilt
from matplotlib import interactive

def main():
	#change the path here to the absolute path, where you downloaded the bagfiles to
	bag_spatula_and_bowl1 = '/home/leus/logs/experiment_with_spatula_and_bowl_2019-09-27-16-21-18.bag'
	bag_no_spatula1 = '/home/leus/logs/experiment_without_spatula_2019-09-27-17-09-42.bag'
	bag_no_bowl1 = '/home/leus/logs/experiment_without_bowl_2019-09-27-17-02-24.bag'
	
	bag_spatula_and_bowl = '/home/leus/force_test_bag/experiment_with_spatula_and_bowl_2019-10-07-21-45-53.bag'
	bag_no_spatula = '/home/leus/force_test_bag/experiment_without_spatula_2019-10-07-22-00-52.bag'
	bag_no_bowl = '/home/leus/force_test_bag/experiment_without_bowl_2019-10-07-21-51-21.bag'
	bag_5up = '/home/leus/force_test_bag/experiment_with_spatula_and_bowl_5mm_up_2019-10-07-22-21-24.bag'
	bag_15up = '/home/leus/force_test_bag/experiment_with_spatula_and_bowl_15mm_up_2019-10-07-22-32-14.bag'

	#change the joint here to the joint you want to plot
	joint = "r_forearm_roll_joint"

	d_15up = data_analysis(joint,bag_15up, bagtype = "15_up")
	d_15up.extract_bag_data()
	d_15up.split_data()
	d_15up.color = 'firebrick'

	d_5up = data_analysis(joint,bag_5up, bagtype = "5_up")
	d_5up.extract_bag_data()
	d_5up.split_data()
	d_5up.color = 'darksalmon'

	d_spatula_and_bowl = data_analysis(joint,bag_spatula_and_bowl)
	d_spatula_and_bowl.extract_bag_data()
	d_spatula_and_bowl.split_data()
	d_spatula_and_bowl.color = 'r'

	d_no_spatula = data_analysis(joint,bag_no_spatula)
	d_no_spatula.extract_bag_data()
	d_no_spatula.split_data()
	d_no_spatula.color = 'b'
	
	d_no_bowl = data_analysis(joint,bag_no_bowl)
	d_no_bowl.extract_bag_data()
	d_no_bowl.split_data()
	d_no_bowl.color = 'g'

	d_spatula_and_bowl1 = data_analysis(joint,bag_spatula_and_bowl1)
	d_spatula_and_bowl1.extract_bag_data()
	d_spatula_and_bowl1.split_data()
	d_spatula_and_bowl1.color = 'darkorange'

	d_no_spatula1 = data_analysis(joint,bag_no_spatula1)
	d_no_spatula1.extract_bag_data()
	d_no_spatula1.split_data()
	d_no_spatula1.color = 'royalblue'
	
	d_no_bowl1 = data_analysis(joint,bag_no_bowl1)
	d_no_bowl1.extract_bag_data()
	d_no_bowl1.split_data()
	d_no_bowl1.color = 'lightgreen'
	

	if joint[0] == "l":
		print "you picked a joint from left arm, plotting spatula_and_bowl and no_spatula"
		data_list = [d_spatula_and_bowl,d_no_spatula,d_5up,d_15up]
	elif joint[0] == "r":
		print "you picked a joint from right arm, plotting spatula_and_bowl and no_bowl"
		data_list = [d_15up,d_spatula_and_bowl,d_no_bowl,d_5up,d_spatula_and_bowl1,d_no_bowl1]
	else:
		print "you picked a joint that is not from either arm plotting all three experiments"
		data_list = [d_spatula_and_bowl,d_no_spatula,d_no_bowl,d_5up,d_15up]

	plot_data(data_list, show_av2=True, interactive_plot=True) 
	#eg. add argument cutoff_f = 10, to apply lowpass filter with cutoff frequency 10 to the effort
	#add interactive_plot=True to make the programm run further without having to close the plot
	plot_filtered_unfiltered(d_spatula_and_bowl, cutoff_f=5)


class data_analysis:

	def __init__(self,joint_name,path,debug_mode=False, bagtype = None):
		self.bag = rosbag.Bag(path)
		print self.bag
		self.joint_name = joint_name
		self.debug_mode = debug_mode
		self.bag_type = bagtype

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
		for topic, msg, t in self.bag.read_messages(''):
		    if topic != "/joint_states":
		        #print "skipping topic %s for now." % topic 
		        continue
		    self.effort.append(msg.effort)
		    self.position.append(msg.position)
		    self.velocity.append(msg.velocity)
		    if first:
		        self.name = msg.name
		        cmd_indices_bag = []
		        for joint in self.cmd_joints:
		            if joint in self.name:
		                cmd_indices_bag.append(self.name.index(joint))
		        first = False
		    
		    pos_array = np.array(msg.position)
		    if self.debug_mode:
		        if np.sum(np.abs((pos_array[cmd_indices_bag]-self.av_1)/self.av_1)) < min_diff:
		        	min_diff = np.sum(np.abs((pos_array[cmd_indices_bag]-self.av_1)/self.av_1))
		        if np.sum(np.abs((pos_array[cmd_indices_bag]-self.av_1)/self.av_1)) > max_diff:
		        	max_diff = np.sum(np.abs((pos_array[cmd_indices_bag]-self.av_1)/self.av_1))

		    diff_limit = 1.1 
		    if np.sum(np.abs((pos_array[cmd_indices_bag]-self.av_1)/self.av_1)) < diff_limit:
		        n_split = n_split + 1 
		        split_window[np.sum(np.abs((pos_array[cmd_indices_bag]-self.av_1)/self.av_1))] = i

		    elif split_window:
		    	self.split_indices.append(split_window[np.min(split_window.keys())])
		        split_window = dict()

		    if np.sum(np.abs((pos_array[cmd_indices_bag]-self.av_2)/self.av_2)) < diff_limit:
		        n_split = n_split + 1 
		        av2_window[np.sum(np.abs((pos_array[cmd_indices_bag]-self.av_2)/self.av_2))] = i

		    elif av2_window:
		    	self.av2_indices.append(av2_window[np.min(av2_window.keys())])
		        av2_window = dict()
		    i = i+1

		#Hack for 15mm up
		if self.bag_type is "15_up":
			self.av2_indices = np.array(self.av2_indices) - np.array(self.split_indices[0:19])#KO
		else:
			self.av2_indices = np.array(self.av2_indices) - np.array(self.split_indices)

		#print "split indices"
		#print self.split_indices

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
		self.n_exp = len(self.split_indices)
		effort_shape = np.shape(self.effort)
		n_joint = effort_shape[1]
		tmp_indices = self.split_indices[0:-1]
		tmp_indices.insert(0,0)
		self.plot_length = np.array(self.split_indices) - np.array(tmp_indices)
		n_time = np.max(np.array(self.split_indices) - np.array(tmp_indices))
		self.split_effort = np.array(np.zeros([self.n_exp,n_time,n_joint]))
		self.split_position = np.array(np.zeros([self.n_exp,n_time,n_joint]))
		i = 0
		for split_ind in self.split_indices:
			diff_ind = split_ind - old_ind
			self.split_effort[i,0:split_ind-old_ind,:] = self.effort[old_ind:split_ind,:]
			self.split_position[i,0:split_ind-old_ind,:] = self.position[old_ind:split_ind,:]
			old_ind = split_ind
			i = i+1


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
	fig, axs = plt.subplots(2, 1)
	for data in data_list:
		for i in range(start_ind,data.n_exp):
			#print data.plot_length
			list_split_effort = list(data.split_effort[i,:,data.ind_joint])
			#length = list_split_effort.index(0) #here!!!
			length = data.plot_length[i]
			t1 = np.array(range(length))
			s1 = data.split_effort[i,0:length,data.ind_joint]
			if cutoff_f is not None:
				s1 = butter_lowpass_filter(s1, cutoff_f, fs, order)
			axs[0].plot(t1, s1, data.color)

		for i in range(start_ind,data.n_exp):
			list_split_effort = list(data.split_effort[i,:,data.ind_joint])
			#length = list_split_effort.index(0)
			length = data.plot_length[i]
			t2 = np.array(range(length))
			s2 = data.split_position[i,0:length,data.ind_joint]

			axs[1].plot(t2, s2, data.color)

		if show_av2:
			try:
				for av2_idx in data.av2_indices:
					axs[1].plot(av2_idx,data.av_2[data.cmd_joints.index(data.joint_name)],'%s x' % data.color)
			except:
				print "cannot plot av2, as %s is not part of av2" % data.joint_name

	axs[0].set_xlabel('time')
	axs[0].set_ylabel('effort_%s' % data.name[data.ind_joint])
	axs[0].grid(True)  
	axs[1].set_xlabel('time')
	axs[1].set_ylabel('position_%s' % data.name[data.ind_joint])
	axs[1].grid(True) 
	interactive(interactive_plot)
	fig.tight_layout()
	plt.show()

def plot_filtered_unfiltered(data, cutoff_f, order=6, fs=100.3, interactive_plot=False, start_ind = 3):
	t1 = np.array(range(920))
	fig = plt.figure()
	ax = fig.add_subplot(1,1,1)
	for i in range(start_ind,data.n_exp):
		list_split_effort = list(data.split_effort[i,:,data.ind_joint])
		#length = list_split_effort.index(0)
		length = data.plot_length[i]
		t1 = np.array(range(length))
		s1 = data.split_effort[i,0:length,data.ind_joint]
		ax.plot(t1, s1, "deepskyblue")
	for i in range(start_ind,data.n_exp):	
		list_split_effort = list(data.split_effort[i,:,data.ind_joint])
		#length = list_split_effort.index(0)
		length = data.plot_length[i]
		t2 = np.array(range(length))
		s1 = data.split_effort[i,0:length,data.ind_joint]
		s2 = butter_lowpass_filter(s1, cutoff_f, fs, order)
		ax.plot(t2, s2, "blue")
	fig.tight_layout()
	interactive(interactive_plot)
	plt.show()


if __name__ == "__main__":
	main()