#!/usr/bin/env python
import rospy

from std_msgs.msg import Float64
from std_msgs.msg import Bool
from sensor_msgs.msg import JointState
from control_msgs.msg import JointTrajectoryControllerState

import numpy as np 
import h5py
import matplotlib.pyplot as plt
from matplotlib import interactive

class detect_touching:

	def __init__(self):
		self.position = []
		self.all_pos = []
		self.all_pos_2d = []
		self.effort = []
		self.window = 1

		self.first_movement = False
		self.scrape_movement = False

		self.i = 0

		self.data_kind=["/r_arm_controller/state","actual"] #actual,desired, error

		self.joint_name = "r_forearm_roll_joint"
		self.diff_touch_array = []
		self.diff_no_touch_array = []
		self.reaction = []
		self.first_r_arm_controller_state = True

		self.av_1 = (2*np.pi/360) * np.array([49.9331,62.6833,33.1418,127.946,-117.444,-7.41574,-5.72958,51.833,-16.9966,-9.03369,-111.73,-116.714,-76.193,-57.7095,266.18,3.0727,-21.2682])

		#self.touch_threshold = 0.02 * self.window / 50
		self.touch_threshold = 0.0005 * self.window
		#self.no_touch_threshold  = 0.0005 * self.window
		self.no_touch_threshold  = 0.0008 * self.window
		#self.no_touch_threshold  = 0.01 * self.window /50
		self.cmd_joints = ["torso_lift_joint", "l_shoulder_pan_joint","l_shoulder_lift_joint","l_upper_arm_roll_joint","l_elbow_flex_joint","l_forearm_roll_joint","l_wrist_flex_joint","l_wrist_roll_joint","r_shoulder_pan_joint","r_shoulder_lift_joint","r_upper_arm_roll_joint","r_elbow_flex_joint","r_forearm_roll_joint","r_wrist_flex_joint","r_wrist_roll_joint","head_pan_joint","head_tilt_joint"]

	def callback_scrape(self,data):
		if self.first_movement is False:
			self.first_movement = True
		print data
		if True:#self.scrape_movement: #has still old value to decide if former movement was scrape or not
			self.all_pos_2d.append(self.all_pos)
		self.scrape_movement = data.data
		self.i = 0
		#self.all_pos_2d.append(self.all_pos)
		self.all_pos = []
		print "start the movement"

	def callback(self,data):
		diff_limit = 1.1 
		self.length = min(len(self.avg_sequence_touch),len(self.avg_sequence_no_touch))
		#rospy.loginfo(rospy.get_caller_id() + "I heard %s", data.position)
		self.joint_names = data.joint_names
		self.joint_index = self.joint_names.index(self.joint_name)

		if self.data_kind[0] == "joint_states":
			err_positions = data.position
		elif self.data_kind[0] == "/r_arm_controller/state":
			err_positions = data.error.positions
			positions = data.actual.positions
			#synchronize the data
			#do this only once to save time
			if self.first_r_arm_controller_state:
				self.r_arm_controller_indices = []
				for joint in self.joint_names:
					self.r_arm_controller_indices.append(self.cmd_joints.index(joint))
					self.first_r_arm_controller_state = False

		if self.scrape_movement:
			self.position.append(err_positions[self.joint_index])
			self.all_pos.append(err_positions[self.joint_index])

		if len(self.position) is self.window:
			act_sequence = self.position
			self.position = []
			#print "################## shapes #####################"
			#print np.shape(act_sequence)
			#print np.shape(self.avg_sequence_touch[self.i*self.window:self.i*self.window+self.window])
			if np.shape(act_sequence) != np.shape(self.avg_sequence_touch[self.i*self.window:self.i*self.window+self.window]):
				self.scrape_movement = False
				#self.i = 0 #catch if the programm runs for a longer time without finding the right position it just starts from the bginning again

			
			avg_sequence_touch_window = self.avg_sequence_touch[self.i*self.window:self.i*self.window+self.window] #if I use abs I do not have direction (not informative anyways) but count both positive
			avg_sequence_no_touch_window = self.avg_sequence_no_touch[self.i*self.window:self.i*self.window+self.window]

			diff_touch = sum(abs(avg_sequence_touch_window - act_sequence)) #if I use abs I do not have direction (not informative anyways) but count both positive
			diff_no_touch = sum(abs(avg_sequence_no_touch_window - act_sequence))

			#KO have to add something if window is not 1 
			if sum((avg_sequence_touch_window >= act_sequence >= avg_sequence_no_touch_window) or (avg_sequence_touch_window <= act_sequence <= avg_sequence_no_touch_window)) > 1/3 * self.window:
				#print "in between the two"
				#cmd = 1.0
				cmd = sum(abs(act_sequence - avg_sequence_touch_window)) / sum(abs(avg_sequence_no_touch_window - avg_sequence_touch_window))
				if self.scrape_movement:
					self.reaction.append(cmd)
			elif sum((act_sequence >= avg_sequence_touch_window >= avg_sequence_no_touch_window) or (act_sequence <= avg_sequence_touch_window <= avg_sequence_no_touch_window)) > 1/3 * self.window:
				#print "touching too much"
				if abs(act_sequence - avg_sequence_touch_window) <= abs(avg_sequence_no_touch_window - avg_sequence_touch_window) :
					#-1.0
					cmd = -1 * sum(abs(act_sequence - avg_sequence_touch_window)) / sum(abs(avg_sequence_no_touch_window - avg_sequence_touch_window))
				else:
					cmd = -1
				if self.scrape_movement:
					self.reaction.append(cmd)
			elif sum((act_sequence >= avg_sequence_no_touch_window >= avg_sequence_touch_window) or (act_sequence <= avg_sequence_no_touch_window <= avg_sequence_touch_window)) > 1/3 * self.window:
				#print "even less than not touching"
				#cmd = 1.0
				#should not happen if it does it should be some noise or other accident -> no reaction
				cmd = 0
				if self.scrape_movement:
					self.reaction.append(cmd)
			else: #if either avg_sequence_touch or avg_sequence_no_touch is empty ([])
				print "empty array"
				cmd = 0.0
				#print avg_sequence_touch_window
				#print avg_sequence_no_touch_window
				#print act_sequence
				#print "touch:"
				#print avg_sequence_touch_window - act_sequence
				#print "no touch:"
				#print avg_sequence_no_touch_window - act_sequence
			"""
			diff_touch = sum(abs(self.avg_sequence_touch[self.i*self.window:self.i*self.window+self.window] - act_sequence)) #if I use abs I do not have direction (not informative anyways) but count both positive
			diff_no_touch = sum(abs(self.avg_sequence_no_touch[self.i*self.window:self.i*self.window+self.window] - act_sequence))
			
			if self.scrape_movement:
				self.diff_touch_array.append(diff_touch)
				self.diff_no_touch_array.append(diff_no_touch)

			if diff_touch > self.touch_threshold and diff_no_touch <= self.no_touch_threshold:
				#robot is not touching the bowl -> move towards spatula
				cmd = 1.0
				if self.scrape_movement:
					self.reaction.append(1)
			elif diff_touch > self.touch_threshold and diff_no_touch > self.no_touch_threshold:
				#robot is touching the bowl too much -> move away from spatula
				cmd = -1.0
				if self.scrape_movement:
					self.reaction.append(-1)
			else:
				#print "everything alright it is touching!" -> nothing has to be done
				cmd = 0.0
				if self.scrape_movement:
					self.reaction.append(0)
			"""

			if self.scrape_movement: #self.first_movement:
				#rospy.loginfo(hello_str) #KO
				self.pub.publish(cmd)
			self.i = self.i + 1

	def debug_plot(self):
		fig, axs = plt.subplots(3, 1)
		first = True

		for element in self.all_pos_2d:
			print "new element"
			print np.shape(element)
			if not element:
				print "skipping empty element"
				continue
			if first:
				print "first element"
				sequence = element[0:len(self.avg_sequence_touch)]
				avg_sequence_touch = list(self.avg_sequence_touch)
				max_sequence_touch = list(self.max_sequence_touch)
				min_sequence_touch = list(self.min_sequence_touch)
				avg_sequence_no_touch = list(self.avg_sequence_no_touch)
				max_sequence_no_touch = list(self.max_sequence_no_touch)
				min_sequence_no_touch = list(self.min_sequence_no_touch)
				first = False
			else:
				print "not first element"
				#axs[0].plot(range(len(element)), element, "blue")
				sequence = sequence + element[0:len(self.avg_sequence_touch)]
				print np.shape(avg_sequence_touch)
				print np.shape(self.avg_sequence_touch)
				avg_sequence_touch = avg_sequence_touch + list(self.avg_sequence_touch)
				max_sequence_touch = max_sequence_touch + list(self.max_sequence_touch)
				min_sequence_touch = min_sequence_touch + list(self.min_sequence_touch)
				avg_sequence_no_touch = avg_sequence_no_touch + list(self.avg_sequence_no_touch)
				max_sequence_no_touch = max_sequence_no_touch + list(self.max_sequence_no_touch)
				min_sequence_no_touch = min_sequence_no_touch + list(self.min_sequence_no_touch)
			#first = False

		axs[0].plot(range(len(avg_sequence_touch)),avg_sequence_touch,"firebrick")
		axs[0].plot(range(len(max_sequence_touch)),max_sequence_touch,"darksalmon")
		axs[0].plot(range(len(min_sequence_touch)),min_sequence_touch,"darksalmon")

		axs[0].plot(range(len(avg_sequence_no_touch)),avg_sequence_no_touch,"c")
		axs[0].plot(range(len(max_sequence_no_touch)),max_sequence_no_touch,"powderblue")
		axs[0].plot(range(len(min_sequence_no_touch)),min_sequence_no_touch,"powderblue")

		axs[0].plot(range(len(sequence)),sequence)

		axs[1].plot(range(len(self.diff_touch_array)),self.diff_touch_array,"firebrick")
		axs[1].plot(range(len(self.diff_no_touch_array)),self.diff_no_touch_array,"c")

		axs[2].plot(range(len(self.reaction)),self.reaction)
		fig.suptitle("difference to touching in red, difference to not touchign in blue, real touching")
		interactive(False)
		plt.show()

def main():

	DetectTouch = detect_touching()

	f = h5py.File("/home/leus/scraping-bowl-v1/desired_trajectory.hdf5","r")
	DetectTouch.avg_sequence_touch = f["touching/avg_position"][0::]
	DetectTouch.max_sequence_touch = f["touching/max_position"][0::]
	DetectTouch.min_sequence_touch = f["touching/min_position"][0::]
	DetectTouch.avg_sequence_no_touch = f["not_touching/avg_position"][0::]
	DetectTouch.max_sequence_no_touch = f["not_touching/max_position"][0::]
	DetectTouch.min_sequence_no_touch = f["not_touching/min_position"][0::]
	f.close()

	print ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
	print type(DetectTouch.avg_sequence_touch)
	print np.shape(DetectTouch.avg_sequence_touch)

	fig, axs = plt.subplots(2, 1)
	axs[0].plot(range(len(DetectTouch.avg_sequence_touch)),DetectTouch.avg_sequence_touch,"firebrick")
	axs[0].plot(range(len(DetectTouch.max_sequence_touch)),DetectTouch.max_sequence_touch,"darksalmon")
	axs[0].plot(range(len(DetectTouch.min_sequence_touch)),DetectTouch.min_sequence_touch,"darksalmon")

	axs[0].plot(range(len(DetectTouch.avg_sequence_no_touch)),DetectTouch.avg_sequence_no_touch,"c")
	axs[0].plot(range(len(DetectTouch.max_sequence_no_touch)),DetectTouch.max_sequence_no_touch,"powderblue")
	axs[0].plot(range(len(DetectTouch.min_sequence_no_touch)),DetectTouch.min_sequence_no_touch,"powderblue")

	fig.suptitle("average max and min error of position of r_arm_controller_state")
	interactive(True)
	plt.show()

	DetectTouch.pub = rospy.Publisher('feedback_touching', Float64, queue_size=10)
	rospy.init_node('detect_touching', anonymous=True)
	#rospy.Subscriber("joint_states", JointState, DetectTouch.callback)
	rospy.Subscriber("/r_arm_controller/state", JointTrajectoryControllerState, DetectTouch.callback)
	rospy.Subscriber("/start_scraping", Bool, DetectTouch.callback_scrape)
	rospy.spin()

	DetectTouch.debug_plot()


if __name__ == "__main__":
    main()