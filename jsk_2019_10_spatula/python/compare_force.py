#!/usr/bin/env python
import rospy
from jsk_2019_10_spatula.msg import Force
import numpy as np
from std_msgs.msg import String, Float64
import json
import matplotlib.pyplot as plt

path_json = "force.json"
resample = True
offline = False
debug = False
feedback_whole_action = True

def main():
	Compare = CompareForce()
	#for offline tests
	if offline:
		Compare.action = "av5transfer"
		Compare.read_force()

		Compare.force["larm"] = np.transpose([[1,1,1,2,3,4,5],[1,1,1,2,3,4,5],[1,1,1,2,3,4,5]])
		Compare.force["rarm"] = np.transpose([[1,1,1,2,3,4,5],[1,1,1,2,3,4,5],[1,1,1,2,3,4,5]])
		Compare.compare()
		Compare.plot_save_up_down()
	else:
		rospy.init_node('compare_force', anonymous=True)
		rospy.Subscriber("endeffector_force", Force, Compare.callback_force)
		rospy.Subscriber("semantic_annotation", String, Compare.callback_annotation)
		rospy.spin()

class CompareForce:

	def __init__(self):
		print "init compare force"
		#######################
		###general parameter###
		#######################
		self.window = None#7 #the time window over which th mean is calculated
		self.logging_rate = 100
		window_approx = 4
		if not resample:
			self.window = window_approx
		self.time_window = window_approx * 1.0 / self.logging_rate; #averaging over 1/10 second which is around 6-10 samples depending on the Force publishing rate
		#KO not integrated yet
		self.min_sample = 5 #if the number of samples is less than min_sample the force is not compared
		#can also skip some that seem to not work well!
		self.action_force = {	"av3wall-0-1":{"arm":"larm","direction":2,"indices":[0,30]},
								"av3wall-0-2":{"arm":"larm","direction":2,"indices":[20,40]},
								"av3wall-0-3":{"arm":"larm","direction":2,"indices":[80,100]},
								"av3wall-0-4":{"arm":"larm","direction":2,"indices":[80,100]},
								"av3wall-1-3":{"arm":"larm","direction":2,"indices":[80,100]},
								"av3wall-1-4":{"arm":"larm","direction":2,"indices":[80,100]},
								"av3wall-2-1":{"arm":"larm","direction":2,"indices":[60,100]},
								"av3wall-2-2":{"arm":"larm","direction":2,"indices":[60,100]},
								"av3wall-2-3":{"arm":"larm","direction":2,"indices":[80,100]},
								"av3wall-2-4":{"arm":"larm","direction":2,"indices":[80,100]},
								"av3wall-3-1":{"arm":"larm","direction":2,"indices":[60,100]},
								"av3wall-3-2":{"arm":"larm","direction":2,"indices":[60,100]},#maybe 80?
								"av3wall-3-3":{"arm":"larm","direction":2,"indices":[60,100]},
								"av3wall-3-4":{"arm":"larm","direction":2,"indices":[80,100]}} #dictionary mapping the relevant force to an action
		self.label_up = "long"
		self.label_down = "short"

		self.pub = rospy.Publisher("force_err", Float64, queue_size=2)
		self.force = {}
		self.force["larm"] = []
		self.force["rarm"] = []
		self.force_des = {}
		self.force_des["larm"] = dict()
		self.force_des["rarm"] = dict()
		self.force_dict = {}
		self.label = []
		self.n_exp = {}
		self.n_t = {}
		self.n_sample = 0 #is used to count up the time during one task to synchronize
		self.action_status = 0
		self.action = None
		self.start_time_action = 0
		self.start_time_window = 0
		self.time_sequence = 0
		self.ts =[]

		#to see if filter work correct
		if debug:
			self.save_up = {}
			self.save_down = {}
			self.save_up["max"] = []
			self.save_up["min"] = []
			self.save_up["mean"] = []
			self.save_up["all"] = []
			self.save_down["max"] = []
			self.save_down["min"] = []
			self.save_down["mean"] = []
			self.save_down["all"] = []
			self.save_actual = []
		self.read_json(path_json)


	def callback_force(self,msg):
		if self.action_status == 0:
			return True
		self.n_sample = self.n_sample + 1
		if self.resample:
			time = rospy.get_time()
			action_time = time - self.start_time_action
			self.time_sequence =  time - self.start_time_window
			self.ts.append(action_time)
		self.force["larm"].append(msg.larm)
		self.force["rarm"].append(msg.rarm)
		if self.action not in self.action_force.keys():
			return True
		if not feedback_whole_action and not resample and np.shape(self.force[self.action_force[self.action]["arm"]])[0] == self.window:# and np.all(self.n_sample < np.array(self.n_t[self.action])):
			self.compare()
		if  not feedback_whole_action and resample and self.time_sequence > self.time_window:
			self.compare()

	def callback_annotation(self,msg):
		[self.action,flag] = msg.data.split("_")
		print "action: %s , type: %s" % (self.action,flag)
		if flag == "start":
			self.debug_start_time = rospy.get_time()
			if self.action not in self.action_force.keys():
				self.action_status = 0
				return True
			if resample:
				self.start_time_action = rospy.get_time()
				self.start_time_window = rospy.get_time()
			self.read_force()
			self.n_sample = 0
			self.force["larm"] = []
			self.force["rarm"] = []
			self.action_status = 1

		if flag == "end":
			if self.time_sequence > self.time_window:
				if self.action in self.action_force.keys():
					self.compare()
			self.action_status = 0
			self.ts = []

		if debug and self.action == "av3wall-0-1" and flag == "end":
			self.plot_save_up_down()

	def read_json(self,path):
		f = open(path,"r")
		force_dict_str = f.read()
		f.close()
		exec("self.force_dict = %s" % force_dict_str)
		self.label = np.array(self.force_dict["label"]) #indexing with i, the index of exp
		self.n_exp = self.force_dict["n_exp"] #indexing with action
		self.n_t = self.force_dict["n_t"] #indexing with action

	def read_force(self):
		force_des_larm = np.array(self.force_dict["force"][self.action]["larm"])[:,:,0:len(self.label)]
		force_des_rarm = np.array(self.force_dict["force"][self.action]["rarm"])[:,:,0:len(self.label)]

		force_des_larm_up = force_des_larm[:,:,self.label == self.label_up]
		force_des_larm_down = force_des_larm[:,:,self.label == self.label_down]

		force_des_rarm_up = force_des_rarm[:,:,self.label == self.label_up]
		force_des_rarm_down = force_des_rarm[:,:,self.label == self.label_down]

		self.force_des["larm"]["up"] =  force_des_larm_up
		self.force_des["larm"]["down"] = force_des_larm_down
		self.force_des["rarm"]["up"] =  force_des_rarm_up
		self.force_des["rarm"]["down"] = force_des_rarm_down

	def compare(self):
		if resample:
			ts = self.ts
			self.start_time_window = rospy.get_time() #start of a new time sequence
			if feedback_whole_action:
				start_index = self.action_force[self.action]["indices"][0]
				stop_index = self.action_force[self.action]["indices"][1]
			else:
				start_ts = ts[0]
				stop_ts = ts[-1]
				start_index = int(round(start_ts*self.logging_rate))
				stop_index = int(round(stop_ts*self.logging_rate))
			arm = self.action_force[self.action]["arm"]
			direction = self.action_force[self.action]["direction"]
			
			if stop_index > np.shape(self.force_des[arm]["up"])[0]:
				stop_index = np.shape(self.force_des[arm]["up"])[0]
			self.window = stop_index - start_index
			print "window: %d" % self.window
		
		if resample:
			actual = self.mean_filter(self.resample(ts,np.array(self.force[arm])[:,direction])[start_index:stop_index]) 
		else:
			actual = self.mean_filter(np.array(self.force[arm])[:,direction]) 

		if debug:
			self.save_actual = self.resample(ts,np.array(self.force[arm])[:,direction])[start_index:stop_index]
		self.force["larm"] = []
		self.force["rarm"] = []
		self.ts = []

		if resample:
			up = self.force_des[arm]["up"][start_index:stop_index, direction, :]
			down = self.force_des[arm]["down"][start_index:stop_index, direction, :]
		else:
			up = self.force_des[arm]["up"][self.n_sample - self.window : self.n_sample , direction, :]
			down = self.force_des[arm]["down"][self.n_sample - self.window : self.n_sample , direction, :]

		up_mean = []
		down_mean = []
		for i in range(np.shape(up)[1]):
			if np.any(up[:,i]==0): #in reality a signal is never exactly 0, only if it still consits of the default value
				up_mean.append(0)
			else:
				up_mean.append(self.mean_filter(up[:,i]))

		for i in range(np.shape(down)[1]):
			if np.any(down[:,i]==0):
				down_mean.append(0)
			else:
				down_mean.append(self.mean_filter(down[:,i]))

		up_mean = np.array(up_mean)
		down_mean= np.array(down_mean)
		if debug:
			self.save_up["all"].append(np.transpose(up))
			self.save_down["all"].append(np.transpose(down))

		#averaging/maximum/minimum over experiments next
		up_dict = {}
		down_dict = {}
		#don't compute err if the data available is less than 50%, only necessary if not resampled
		if float(len(up_mean[up_mean != 0])) / len(up_mean) < 0.5 or float(len(down_mean[down_mean != 0])) / len(down_mean) < 0.5:
			print "too little signals"
			return True
		up_dict["max"] = np.max(up_mean[up_mean != 0])
		up_dict["min"] = np.min(up_mean[up_mean != 0])
		up_dict["mean"] = np.mean(up_mean[up_mean != 0])
		down_dict["max"] = np.max(down_mean[down_mean != 0])
		down_dict["min"] = np.min(down_mean[down_mean != 0])
		down_dict["mean"] = np.mean(down_mean[down_mean != 0])
		if debug:
			self.save_up["max"].append(np.max(up_mean[up_mean != 0]))
			self.save_up["min"].append(np.min(up_mean[up_mean != 0]))
			self.save_up["mean"].append(np.mean(up_mean[up_mean != 0]))
			self.save_down["max"].append(np.max(down_mean[down_mean != 0]))
			self.save_down["min"].append(np.min(down_mean[down_mean != 0]))
			self.save_down["mean"].append(np.mean(down_mean[down_mean != 0]))
		err = self.compute_err(up_dict,down_dict,actual)
		print "err: %f" % err #err should be published
		if not offline:
			self.pub.publish(err)

	def resample(self,ts,signal):
		if feedback_whole_action:
			arm = self.action_force[self.action]["arm"]
			stretched_signal = np.interp(np.linspace(ts[0],ts[-1],np.shape(self.force_des[arm]["up"])[0]),ts,signal)
		else:
			stretched_signal = np.interp(np.linspace(ts[0],ts[-1],self.window),ts,signal)
		return stretched_signal

	def mean_filter(self,signal):
		if len(signal) != self.window:
			print "CAUTION window size:%d  singal length:%d " % (self.window,len(signal))
		mean = sum(signal)/len(signal)
		return mean

	def compute_err(self,up,down,actual):
		d1 = actual - down["mean"]
		d2 = up["mean"] - down["mean"]
		print "d1: %f" % d1
		print "d2: %f" % d2
		#only protection from division by 0
		if d2 == 0:
			return 0
		else:
			err = d1/d2 * (3.0/4.0) #the second av is not 2cm down but 3cm down
		return err

	def plot_signal(self,signal,color = "royalblue"):
		"""
		signal: np array of size t x n
		plots each of the n signals in a seperate subplot
		"""
		n = np.shape(signal)[1]
		fig, axs = plt.subplots(n, 1)
		for i in range(n):
			axs[i].plot(signal[:,i],color)
		plt.show()

	def plot_save_up_down(self):
		color = "royalblue"
		fig, axs = plt.subplots(2, 1)
		for i in range(np.shape(self.save_up["all"])[1]):
			signal_up = np.array(self.save_up["all"])[:,i]
			axs[1].plot(signal_up[signal_up!=0], "lightseagreen")
		for i in range(np.shape(self.save_down["all"])[1]):
			signal_down = np.array(self.save_down["all"])[:,i]
			axs[1].plot(signal_down[signal_down!=0], "maroon")

		line2, = axs[1].plot(self.save_up["mean"], "blue")
		line2, = axs[1].plot(self.save_up["max"], "blue")
		line2, = axs[1].plot(self.save_up["min"], "blue")

		line2, = axs[1].plot(self.save_down["mean"], "red")
		line2, = axs[1].plot(self.save_down["max"], "red")
		line2, = axs[1].plot(self.save_down["min"], "red")
		axs[1].plot(self.save_actual,"orange")
		plt.show()



if __name__ == "__main__":
    main()


