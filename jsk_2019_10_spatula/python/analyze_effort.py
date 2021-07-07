#!/usr/bin/env python
import rosbag
import matplotlib.pyplot as plt
import numpy as np
from jsk_2019_10_spatula.msg import Jacobian, Force
from control_msgs.msg import JointTrajectoryControllerState
import rospy
import tf

offline = False
#if published seperate ~100Hz, togetehr ~50Hz
publish_force_seperate = False
simulation_hack = False


def main():
    if not offline:
        rospy.init_node('calculate_force', anonymous=True)
    Analyzer = AnalyzeEffort()
    path = "/home/leus/bag_trafo_jacobi/2019-12-13-17-34-48.bag"

    if offline:
        Analyzer.read_bag(path)
        Analyzer.calculate_force("larm")
        fig, axs = plt.subplots(3, 1)
        axs[0].plot(np.transpose(Analyzer.force["larm"][0]))
        axs[1].plot(np.transpose(Analyzer.force["larm"][1]))
        axs[2].plot(np.transpose(Analyzer.force["larm"][2]))
        plt.show()

    else:
        rospy.Subscriber("/scrape_left_jacobian", Jacobian, Analyzer.callback_left_jacobian)
        rospy.Subscriber("/torso_controller/state", JointTrajectoryControllerState, Analyzer.callback_torso_controller)
        rospy.Subscriber("/l_arm_controller/state", JointTrajectoryControllerState, Analyzer.callback_larm_controller)
        rospy.Subscriber("/scrape_right_jacobian", Jacobian, Analyzer.callback_right_jacobian)
        rospy.Subscriber("/r_arm_controller/state", JointTrajectoryControllerState, Analyzer.callback_rarm_controller)
        rospy.spin()


class AnalyzeEffort():
    def __init__(self):
        print "init AnalyzeEffort"
        self.effort = {"larm": {"desired":[],"error":[],"actual":[]},"rarm": {"desired":[],"error":[],"actual":[]},"torso": {"desired":[],"error":[],"actual":[]}}
        self.position = {"larm": {"desired":[],"error":[],"actual":[]},"rarm": {"desired":[],"error":[],"actual":[]},"torso": {"desired":[],"error":[],"actual":[]}}
        self.velocity = {"larm": {"desired":[],"error":[],"actual":[]},"rarm": {"desired":[],"error":[],"actual":[]},"torso": {"desired":[],"error":[],"actual":[]}}
        self.joint_names = []
        self.jacobian = {"larm":np.zeros([6,8]),"rarm":np.zeros([6,8])}
        self.small_jacobiT = {"larm":np.zeros([3,3]),"rarm":np.zeros([3,3])}
        self.force = {"larm":[],"rarm":[]}
        self.force_radial = {"larm":[],"rarm":[]}
        self.joint_names = {"larm":[],"rarm":[]}
        if not offline:
            self.listener = tf.TransformListener()
            self.jacobian_published_left = False
            self.jacobian_published_right = False
            self.force_calculated_left = False
            self.force_calculated_right = False
            if publish_force_seperate:
                self.pub_l = rospy.Publisher("endeffector_force_l", Force, queue_size=2)
                self.pub_r = rospy.Publisher("endeffector_force_r", Force, queue_size=2)
            else:
                self.pub = rospy.Publisher("endeffector_force", Force, queue_size=2)
        np.set_printoptions(formatter={'float': '{: 0.3f}'.format})

    def read_bag(self,path):
        self.bag = rosbag.Bag(path)
        first_joint_names_left = True
        first_jacobi_left = True
        for topic, msg, t in self.bag.read_messages(''):
            if topic == "/scrape_left_jacobian" and first_jacobi_left:
                self.unpack_jacobi(msg,"larm")
                print self.jacobian["larm"]
                first_jacobi_left = False

            elif topic == "/torso_controller/state":
                self.unpack_controller(msg,"torso")

            elif topic == "/l_arm_controller/state":
                if first_joint_names_left:
                    self.joint_names["larm"] = msg.joint_names
                    first_joint_names_left = False
                self.unpack_controller(msg,"larm")

    def callback_left_jacobian(self,jacobian):
        self.unpack_jacobi(jacobian,"larm")
        self.jacobian_published_left = True

    def callback_right_jacobian(self,jacobian):
        self.unpack_jacobi(jacobian,"rarm")
        self.jacobian_published_right = True

    def callback_larm_controller(self,msg):
        #empty the arrrays for left arm -> only newest values in there
        self.effort["larm"] = {"desired":[],"error":[],"actual":[]}
        self.position["larm"] = {"desired":[],"error":[],"actual":[]}
        self.velocity["larm"] = {"desired":[],"error":[],"actual":[]}
        self.unpack_controller(msg,"larm")
        if self.jacobian_published_left:
            self.calculate_force("larm")
            if publish_force_seperate:
                force = Force()
                force.larm = self.force["larm"]
                self.pub_l.publish(force)
            else:
                if self.force_calculated_right:
                    self.publish_force()
                else:
                    self.force_calculated_left = True
            
    def publish_force(self):
        force = Force()
        force.larm = self.force["larm"]
        force.rarm = self.force["rarm"]
        self.pub.publish(force)
        self.force_calculated_right = False
        self.force_calculated_left = False


    def callback_rarm_controller(self,msg):
        #empty the arrays for left arm -> only newest values in there
        self.effort["rarm"] = {"desired":[],"error":[],"actual":[]}
        self.position["rarm"] = {"desired":[],"error":[],"actual":[]}
        self.velocity["rarm"] = {"desired":[],"error":[],"actual":[]}
        self.unpack_controller(msg,"rarm")
        if self.jacobian_published_right:
            self.calculate_force("rarm")
            if publish_force_seperate:
                force = Force()
                force.rarm = self.force["rarm"]
                self.pub_r.publish(force)
            else:
                if self.force_calculated_left:
                    self.publish_force()
                else:
                    self.force_calculated_right = True
            


    def callback_torso_controller(self,msg):
        #empty the arrrays for left arm -> only newest values in there
        self.effort["torso"] = {"desired":[],"error":[],"actual":[]}
        self.position["torso"] = {"desired":[],"error":[],"actual":[]}
        self.velocity["torso"] = {"desired":[],"error":[],"actual":[]}
        self.unpack_controller(msg,"torso")

    def unpack_controller(self,msg,controller_type):
        self.effort[controller_type]["desired"].append(msg.desired.effort)
        self.effort[controller_type]["error"].append(msg.error.effort)
        self.effort[controller_type]["actual"].append(msg.actual.effort)
        self.position[controller_type]["desired"].append(msg.desired.positions)
        self.position[controller_type]["error"].append(msg.error.positions)
        self.position[controller_type]["actual"].append(msg.actual.positions)
        self.velocity[controller_type]["desired"].append(msg.desired.velocities)
        self.velocity[controller_type]["error"].append(msg.error.velocities)
        self.velocity[controller_type]["actual"].append(msg.actual.velocities)

    def unpack_jacobi(self,jacobian,arm):
        self.jacobian[arm][0,:] = jacobian.x
        self.jacobian[arm][1,:] = jacobian.y
        self.jacobian[arm][2,:] = jacobian.z
        self.jacobian[arm][3,:] = jacobian.roll
        self.jacobian[arm][4,:] = jacobian.pitch
        self.jacobian[arm][5,:] = jacobian.yaw

    def get_small_jacobi(self,i,j,k,arm):
        self.small_jacobiT[arm][0,:] = np.transpose(self.jacobian[arm])[i,0:3]
        self.small_jacobiT[arm][1,:] = np.transpose(self.jacobian[arm])[j,0:3]
        self.small_jacobiT[arm][2,:] = np.transpose(self.jacobian[arm])[k,0:3]

    def transform_jacobi(self,r,arm):
        T = np.vstack([np.hstack([np.eye(3), -self.skew(r)]) , np.hstack([np.zeros([3,3]),np.eye(3)])])
        self.jacobian[arm] = np.matmul(T,self.jacobian[arm])


    def skew(self,v):
        v_hat = np.array([[0,-v[2],v[1]], [v[2],0,-v[0]], [-v[1],v[0],0]])
        return v_hat

    def calculate_force(self,arm,i=1,j=3,k=4,least_square=True):
        #KO hack!!
        if simulation_hack:
            effortT = np.transpose(self.position[arm]["error"]) #necessary as effort is not published in simulation
        else:
            effortT = np.transpose(self.effort[arm]["actual"])
        if least_square:
            #self.force[arm] = np.linalg.lstsq(np.transpose(self.jacobian[arm][:,1:8]),effortT)[0][0:3]
            force_local = np.linalg.lstsq(np.transpose(self.jacobian[arm][:,1:8]),effortT)[0][0:3]
            #self.force = np.linalg.lstsq(np.transpose(self.jacobian),np.vstack([effortT[:,0:10445],np.transpose(self.effort["torso"]["actual"])]))[0]
        else:
            self.get_small_jacobi(i,j,k,"larm")
            effortT_small = np.array([effortT[i-1],effortT[j-1],effortT[k-1]])
            self.force[arm] = np.matmul(np.linalg.inv(self.small_jacobiT[arm]),effortT_small)
        if not offline:
            r = self.calculate_r()
            Fr = np.dot(force_local.flatten(),r) #r is unit vector in radial direction
            self.force[arm] = np.append(force_local,Fr)


    def calculate_r(self):
        trafo_r = self.get_transform('/r_gripper_tool_frame')
        trafo_l = self.get_transform('/l_gripper_tool_frame')
        yr = np.matmul(trafo_r, np.transpose([0,1,0,0]))[0:3]
        yr = yr * (1/np.linalg.norm(yr))
        zl = np.matmul(trafo_l, np.transpose([0,0,1,0]))[0:3]
        zl = zl * (1/np.linalg.norm(zl))
        r = yr - (np.dot(yr,zl) * zl)
        return (r * (1/np.linalg.norm(r)))

    def get_transform(self,target_frame):
        """
        input           none
        output          trafo:  transformation matrix that transforms from target_frame to '/base_link'
        """
        (trans,rot) = self.listener.lookupTransform('/base_link',target_frame, rospy.Time(0))
        rotmat = self.quat2mat(rot)
        trans_v = np.array(trans)
        trans_v = np.reshape(trans,[3,1])
        trafo = np.vstack([np.hstack([rotmat,trans_v]),np.array([0,0,0,1])])
        return trafo

    def quat2mat(self,quat):
        """
        input           quat 4-element list/array representing a quaternion in the order x,y,z,w
        output          mat, 3x3 array representing a rotation matrix
        description     converts quaternion to rotation matrix
        resources       - http://docs.ros.org/melodic/api/geometry_msgs/html/msg/Quaternion.html
                        - implementation from https://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToMatrix/index.htm
        """
        x = quat[0]
        y = quat[1]
        z = quat[2]
        w = quat[3]
        mat = np.array([[1-(2*(y**2))-(2*(z**2)), 2*x*y-(2*z*w), 2*x*z+(2*y*w)],
                        [2*x*y + 2*z*w, 1-(2*(x**2))-(2*(z**2)), 2*y*z-(2*x*w)],
                        [2*x*z-(2*y*w), 2*y*z + 2*x*w, 1-(2*(x**2))-(2*(y**2))]])
        return mat

    def debug_force(self,arm,i=1,j=3,k=4):
        self.calculate_force(arm,least_square=True)
        #calculate force with least squares
        fig, axs = plt.subplots(3, 1)
        axs[0].plot(np.transpose(self.force[arm][0]),label='least squares')
        axs[1].plot(np.transpose(self.force[arm][1]),label='least squares')
        axs[2].plot(np.transpose(self.force[arm][2]),label='least squares')
        #calculate force with small matrix
        self.calculate_force(arm,i,j,k,least_square=False)
        axs[0].plot(np.transpose(self.force[arm][0]),label='small matrix')
        axs[1].plot(np.transpose(self.force[arm][1]),label='small matrix')
        axs[2].plot(np.transpose(self.force[arm][2]),label='small matrix')
        axs[0].legend()
        axs[1].legend()
        axs[2].legend()
        plt.show()

    def transform_force_radial(self,phi,arm):
        r = np.array([np.cos(phi+np.pi/2),np.sin(phi+np.pi/2),0])
        self.force_radial[arm] = np.matmul(r,self.force[arm])

    def plot_data(self,datatype):
        fig, axs = plt.subplots(8, 1)
        #plot torso joint
        exec("axs[0].plot(self.%s['torso'][datatype[2]])" % (datatype[0]))
        axs[0].set_xlabel('time',fontsize="small")
        axs[0].set_ylabel("torso",fontsize="small")
        axs[0].grid(True)
        #plot all arm joints
        for i, name in enumerate(self.joint_names[datatype[1]]):
            exec("axs[i+1].plot(np.transpose(self.%s[datatype[1]][datatype[2]])[i])" % (datatype[0]))
            axs[i+1].set_xlabel('time',fontsize="small")
            axs[i+1].set_ylabel(name,fontsize="small")
            axs[i+1].grid(True)
        fig.suptitle("%s %s %s " % (datatype[0],datatype[1],datatype[2]))
        plt.show()


if __name__ == "__main__":
    main()