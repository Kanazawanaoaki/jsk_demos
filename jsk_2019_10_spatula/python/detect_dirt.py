#!/usr/bin/env python
import rospy
from sensor_msgs.msg import PointCloud2
from std_msgs.msg import Bool
import sensor_msgs.point_cloud2 as pc2
import numpy as np

from jsk_2019_10_spatula.msg import BoolArray
from jsk_2019_10_spatula.msg import FloatArray



def main():
    rospy.init_node('detect_dirt', anonymous=True)
    Detector = DirtDetector()
    rospy.Subscriber("/pcl_nodelet/hsi_filter_white/output", PointCloud2, Detector.callback_ptcloud_white)
    #rospy.Subscriber("/pcl_nodelet/point_cloud_sequence_merged", PointCloud2, Detector.callback_ptcloud_white)
    rospy.Subscriber("/pcl_nodelet/hsi_filter_brown/output", PointCloud2, Detector.callback_ptcloud_brown)
    rospy.spin()

class DirtDetector():
    def __init__(self):
        #0:clean, 1:dirty
        #########################
        ### Parameters to set ###
        #########################
        self.debug = True  #if the cut pointcloud should be published, set to True
        self.seperate_pieces_debug = False
        #hier passt was nicht mit n_pieces
        #(0,1,2,3,4,5,6, ,8,9,10,11,12,13,14,15)
        n_bowl_positions = 4
        self.n_pieces = 4 * n_bowl_positions  #determine how many different positions the bowl has (has to be the same than in scrape-bowl.l) 
        #determine parameters for cutting off the ptcloud
        #self.m = [0.14,0,0]
        #changed due to gripper change
        self.m = [0.16,0,0]
        #self.m = [0.16,-0.02,0]
        #self.m = [0.16,0.02,0]
        #self.r_middle = 0.05
        #self.r_middle = 0.065
        self.r_middle = 0.07
        #self.r_middle = 0.08
        #self.r_middle = 0.0
        #self.r_bowl = 0.1
        self.r_bowl = 0.12
        #self.r_bowl = 0.3
        #self.z_max = 0.1
        #self.z_max = 0.05
        self.z_max = 0.03
        #self.z_max = 0.08
        #self.z_max = 0.05
        self.z_min = -0.1
        #self.z_min = -0.07

        self.all_borders = dict()
        self.all_borders[0] = [0,0.5/8]
        self.all_borders[1] = [0.5/8,1.0/8]
        self.all_borders[2] = [1.0/8,1.5/8]
        self.all_borders[3] = [1.3/8,1.9/8]
        self.all_borders[4] = [1.7/8,2.5/8]
        self.all_borders[5] = [2.0/8,2.7/8]
        self.all_borders[6] = [2.6/8,3.4/8]
        #self.all_borders[6] = [0,4.0/8]
        self.all_borders[7] = [3.0/8,3.9/8]
        #there is some space inbetween 7 and 8, as this part does not need to be clean
        self.all_borders[8] = [5.2/8,5.8/8]
        self.all_borders[9] = [5.5/8,6.1/8]
        self.all_borders[10] = [5.9/8,6.5/8]
        self.all_borders[11] = [6.2/8,6.8/8]
        self.all_borders[12] = [6.4/8,6.9/8]
        self.all_borders[13] = [6.7/8,7.2/8]
        self.all_borders[14] = [7.0/8,7.5/8]
        self.all_borders[15] = [7.3/8,7.9/8]
        #########################

        self.pub = rospy.Publisher("dirt_label", BoolArray, queue_size=2)
        self.pub_percent = rospy.Publisher("dirt_percent", FloatArray, queue_size=2)
        if self.debug:
            self.pub_white_pieces = rospy.Publisher("white_pieces", PointCloud2, queue_size=2)
            self.pub_brown_pieces = rospy.Publisher("brown_pieces", PointCloud2, queue_size=2)
        self.pub_white = False
        self.pub_brown = False

        

    def callback_ptcloud_brown(self, ptcloud):
        points = self.read_pointcloud(ptcloud)
        if self.debug:
            self.xyz_brown = self.read_points_debug(points,ptcloud,"brown")
        else:
            self.xyz_brown = self.read_points(points)
        self.pub_brown = True
        if self.pub_white:
            self.get_labels()


    def callback_ptcloud_white(self, ptcloud):
        points = self.read_pointcloud(ptcloud)
        if self.debug:
            self.xyz_white = self.read_points_debug(points,ptcloud,"white")
        else:
            self.xyz_white = self.read_points(points)
        self.pub_white = True
        if self.pub_brown:
            self.get_labels()

    def read_pointcloud(self,ptcloud):
        fields = ptcloud.fields
        fields[3].datatype = 6
        points = pc2.read_points_list(ptcloud, skip_nans=True)
        return points

    def read_points(self,points):
        xyz = []
        for point in points:
            xyz.append([point.x,point.y,point.z])
        xyz = np.array(xyz)
        return xyz



    #######################################
    ### publish cut pointcloud to debug ###
    #######################################

    def read_points_debug(self,points,ptcloud,color):
        xyz = []
        rgb = []
        for point in points:
            xyz.append([point.x,point.y,point.z])
            rgb.append(point.rgb)
        xyz = np.array(xyz)
        rgb = np.array(rgb)
        rgb = np.reshape(rgb,[len(rgb),1])

        for i in [0]:#range(self.n_pieces):
            #phi_min = (i)*2*np.pi/self.n_pieces - np.pi
            #phi_max = (i+1)*2*np.pi/self.n_pieces - np.pi
            #aktuelle version
            if self.seperate_pieces_debug:
            	phi_min = self.all_borders[i][0]*2*np.pi - np.pi
            	phi_max = self.all_borders[i][1]*2*np.pi - np.pi
            else:
            	phi_min = (0)*2*np.pi/self.n_pieces - np.pi
            	phi_max = (self.n_pieces)*2*np.pi/self.n_pieces - np.pi

            #workaroudnd fuer veranschaulichung
            #phi_min = self.all_borders[7][0]*2*np.pi - np.pi
            #phi_max = self.all_borders[7][1]*2*np.pi - np.pi
            #with old version
            #phi_min = (0)*2*np.pi/self.n_pieces - np.pi
            #phi_max = (16)*2*np.pi/self.n_pieces - np.pi

            r_phi = np.transpose(np.array([np.sqrt(np.power((xyz[:,0]-self.m[0]),2) + np.power((xyz[:,1]-self.m[1]),2)),np.arctan2(xyz[:,1]-self.m[1],xyz[:,0]-self.m[0])]));
            #xyz_cut = xyz[np.logical_and(np.logical_and( np.logical_and(r_phi[:,0] > self.r_middle, r_phi[:,0] < self.r_bowl), np.logical_and(r_phi[:,1] > phi_min,r_phi[:,1] < phi_max)), np.logical_and(xyz[:,2] > self.z_min,xyz[:,2] < self.z_max)),:]
            #rgb_cut = rgb[np.logical_and(np.logical_and( np.logical_and(r_phi[:,0] > self.r_middle, r_phi[:,0] < self.r_bowl), np.logical_and(r_phi[:,1] > phi_min,r_phi[:,1] < phi_max)), np.logical_and(xyz[:,2] > self.z_min,xyz[:,2] < self.z_max))]        
            #mitte als zylinder abschneiden
            xyz_cut = xyz[np.logical_and(np.logical_and(np.logical_and(np.logical_or(r_phi[:,0] > self.r_middle, xyz[:,2] < self.z_max), r_phi[:,0] < self.r_bowl), np.logical_and(r_phi[:,1] > phi_min,r_phi[:,1] < phi_max)), xyz[:,2] > self.z_min),:]
            rgb_cut = rgb[np.logical_and(np.logical_and(np.logical_and(np.logical_or(r_phi[:,0] > self.r_middle, xyz[:,2] < self.z_max), r_phi[:,0] < self.r_bowl), np.logical_and(r_phi[:,1] > phi_min,r_phi[:,1] < phi_max)), xyz[:,2] > self.z_min)]   

            point_array = np.hstack([xyz_cut,rgb_cut])
            point_list = list(point_array)
            self.generate_pointcloud(ptcloud,point_list,color)

        return xyz

    def generate_pointcloud(self,ptcloud,point_list,color):
        header =  ptcloud.header
        fields = ptcloud.fields

        header.frame_id = "/l_gripper_tool_frame"
        #apparently 'ptcloud_merged.fields[3].datatype = 7' later changes also self.ptcloud.fields[3].datatype = 7
        #call by reference! in case of debugging it messes up the colors, thats why this line is needed
        fields[3].datatype = 6

        ptcloud_merged = pc2.create_cloud(header, fields, point_list)
        ptcloud_merged.fields[3].datatype = 7

        if color is "white":
            self.pub_white_pieces.publish(ptcloud_merged)
        else:
            self.pub_brown_pieces.publish(ptcloud_merged)

    ######################################


    def get_labels(self):        
        percentage = self.calculate_percentage()
        self.pub_brown = False
        self.pub_white = False
        labels = percentage > 0.1
        print percentage
        print labels
        self.pub.publish(labels)
        self.pub_percent.publish(percentage)

    def calculate_percentage(self):
        percentage = np.zeros(self.n_pieces)
        for i in range(self.n_pieces):
            #phi_min = (i)*2*np.pi/self.n_pieces - np.pi
            #phi_max = (i+1)*2*np.pi/self.n_pieces - np.pi
            phi_min = self.all_borders[i][0]*2*np.pi - np.pi
            phi_max = self.all_borders[i][1]*2*np.pi - np.pi
            points_cut_brown = self.cut_points(self.xyz_brown,phi_min,phi_max)
            points_cut_white = self.cut_points(self.xyz_white,phi_min,phi_max)
            shape_brown = np.shape(points_cut_brown)
            shape_white = np.shape(points_cut_white)
            n_brown = shape_brown[0]
            n_white = shape_white[0]
            #KO debug!!!
            try:
                percentage[i] = float(n_brown) / float(n_brown + n_white)
            except:
                percentage[i] = -1
        return percentage

    def cut_points(self,xyz,phi_min,phi_max):    
        r_phi = np.transpose(np.array([np.sqrt(np.power((xyz[:,0]-self.m[0]),2) + np.power((xyz[:,1]-self.m[1]),2)),np.arctan2(xyz[:,1]-self.m[1],xyz[:,0]-self.m[0])]));
        #(r_middle < r < r_bowl) & (phi_min < phi < phi_max) & (z_min < z < z_max)
        #xyz_cut = xyz[np.logical_and(np.logical_and( np.logical_and(r_phi[:,0] > self.r_middle, r_phi[:,0] < self.r_bowl), np.logical_and(r_phi[:,1] > phi_min,r_phi[:,1] < phi_max)), np.logical_and(xyz[:,2] > self.z_min,xyz[:,2] < self.z_max)),:]
        xyz_cut = xyz[np.logical_and(np.logical_and(np.logical_and(np.logical_or(r_phi[:,0] > self.r_middle, xyz[:,2] < self.z_max), r_phi[:,0] < self.r_bowl), np.logical_and(r_phi[:,1] > phi_min,r_phi[:,1] < phi_max)), xyz[:,2] > self.z_min),:]
        return xyz_cut



if __name__ == "__main__":
    main()
