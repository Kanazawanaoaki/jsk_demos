#!/usr/bin/env python
import rospy
from sensor_msgs.msg import PointCloud2
import sensor_msgs.point_cloud2 as pc2
import numpy as np
import ctypes
import struct
from sensor_msgs.msg import PointCloud2, PointField
from std_msgs.msg import Header
import sys

import math


def main():
    #pub = rospy.Publisher('feedback_touching', Float64, queue_size=10)
    Merger = MergePointClouds()
    rospy.init_node('merge_pointcloud', anonymous=True)
    rospy.Subscriber("/pcl_nodelet/hsi_filter_brown/output", PointCloud2, Merger.callback_brown)
    rospy.Subscriber("/pcl_nodelet/hsi_filter/output", PointCloud2, Merger.callback_white)
    rospy.spin()

class MergePointClouds:
    def __init__(self):
        self.pub = rospy.Publisher("point_cloud2", PointCloud2, queue_size=2)
        self.pub_NaN = rospy.Publisher("point_cloud2_NaN", PointCloud2, queue_size=2)
        self.n_brown = 0
        self.n_white = 0

    def callback_white(self,ptcloud):
        self.ptcloud_white = ptcloud
        self.n_white = self.n_white + 1
        print "new white pointcloud available n_brown:%d  n_white:%d" % (self.n_brown,self.n_white)
        self.points_white = self.read_pointcloud(ptcloud)
        if self.n_brown == self.n_white:
            print "publish in white"
            ptcloud_merged,ptcloud_merged_NaN = self.generate_pointcloud()
            self.pub.publish(ptcloud_merged)
            self.pub_NaN.publish(ptcloud_merged_NaN)

    def callback_brown(self,ptcloud):
        print ",,,,,,,,,,,,,,shape;;;;;;;;;;;;;;;;;;;"
        print len(ptcloud.data)
        self.ptcloud_brown = ptcloud
        self.n_brown = self.n_brown + 1
        self.points_brown = self.read_pointcloud(ptcloud)
        print "new brown pointcloud available n_brown:%d  n_white:%d" % (self.n_brown,self.n_white)
        if self.n_brown == self.n_white:
            print "publish in brown"
            ptcloud_merged,ptcloud_merged_NaN = self.generate_pointcloud()
            self.pub.publish(ptcloud_merged)
            self.pub_NaN.publish(ptcloud_merged_NaN)


    def read_pointcloud(self,ptcloud):
        #print ptcloud
        fields = ptcloud.fields
        fields[3].datatype = 6
        points = pc2.read_points_list(ptcloud, skip_nans=False)
        #print "without Nans"
        #print np.shape(points)
        #print "with Nans"
        #print np.shape(pc2.read_points_list(ptcloud, skip_nans=False))
        #points = list(gen) 
        p = []
        if False:
            j = 0
            for x in points:
                #https://github.com/PointCloudLibrary/pcl/issues/1543
                #uint8_t alpha | uint8_t red | uint8_t green | uint8_t blue
                #s111 1111 1xxx xxxx xxxx xxxx xxxx xxxx -> results in NaN
                if False:#math.isnan(x.rgb):
                    #print "NaN in rgb"
                    s = struct.pack('<f' ,x.rgb)
                    i = struct.unpack('<l',s)[0]
                    print "i"
                    print i
                    pack = ctypes.c_uint32(i).value
                    print hex(pack)
                #print x
                #print type(x.rgb)
                s = struct.pack('<f' ,x.rgb)
                i = struct.unpack('<l',s)[0]
                #print "i"
                #print i
                #print i
                pack = ctypes.c_uint32(i).value
                #print "%x" % pack
                #print "size"
                #print sys.getsizeof(hex(pack))
                #print sys.getsizeof(pack)
                #print sys.getsizeof(x.x)
                #print sys.getsizeof(x.y)
                #print sys.getsizeof(x.z)
                #a = ctypes.c_uint32(-2977165).value
                #if it is positive it is 28 Bits negative 32
                #a = ctypes.c_uint32(429496729500).value
                #print sys.getsizeof(a)
                #print points[j].rgb# = pack
                #j = j+1
                p.append([x.x,x.y,x.z,pack])
                #rgb = struct.pack('Q', x.rgb)
                #print rgb
                #for fld in x._fields:
                #    print(fld, getattr(x, fld))
                #test = x[3] 
                # cast float32 to int so that bitwise operations are possible
                #s = struct.pack('>f' ,test)
                #i = struct.unpack('>l',s)[0]
                # you can get back the float value by the inverse operations
                #pack = ctypes.c_uint32(i).value
                #x = ctypes.c_float32(x.x).value
                #print "sizes"
                #print sys.getsizeof(x)
                #print sys.getsizeof(x.x)
                r = (pack & 0x00FF0000)>> 16
                g = (pack & 0x0000FF00)>> 8
                b = (pack & 0x000000FF)
                #print r,g,b # prints r,g,b values in the 0-255 range
                #print sys.getsizeof(r),sys.getsizeof(g),sys.getsizeof(b)
                # x,y,z can be retrieved from the x[0],x[1],x[2]
        return points

    def generate_pointcloud(self):
        header =  self.ptcloud_brown.header
        fields = self.ptcloud_brown.fields
        fields[3].datatype = 6
        print fields[3]
        if False:
            for p in points:
                print np.shape(p)
                x,y,z,r,g,b = p
                rgb = struct.unpack('I', struct.pack('BBB', b, g, r))[0]
                print hex(rgb)
                pt = [x, y, z, rgb]
                points_data.append(pt)

        points = self.points_brown + self.points_white
        #gen = pc2.read_points(self.ptcloud_brown, skip_nans=True)
        #points = list(gen)
        #points = pc2.read_points_list(self.ptcloud_brown, skip_nans=True)
        points_NaN = pc2.read_points_list(self.ptcloud_brown, skip_nans=False)

        #print type(points[0])
        #for fld in points[0]._fields:
        #   print(fld, getattr(points[0], fld))
        #print sys.getsizeof(points[0].x)
        #print sys.getsizeof(points[0].y)
        #print sys.getsizeof(points[0].z)
        #print sys.getsizeof(points[0].rgb)
        
        ptcloud_merged = pc2.create_cloud(header, fields, points)
        ptcloud_merged_NaN = pc2.create_cloud(header, fields, points_NaN)

        if False:
            points2 = pc2.read_points_list(ptcloud_merged, skip_nans=False)
            print "diff in points"
            diffrgb = 0
            diffx = 0
            diffy = 0
            diffz = 0
            diffpack = 0
            for i in range(np.shape(points)[0]):
                diffx = diffx + (points[i].x != points2[i].x)
                diffy = diffy + (points[i].y != points2[i].y)
                diffz = diffz + (points[i].z != points2[i].z)
                if not (math.isnan(points[i].rgb) and math.isnan(points2[i].rgb)): #if both are non the expression will still be true
                    diffrgb = diffrgb + (points[i].rgb != points2[i].rgb)

                #if (math.isnan(points[i].rgb) and math.isnan(points2[i].rgb)):
                #    diffrgb = diffrgb + 1
                s = struct.pack('<f' ,points[i].rgb)
                n = struct.unpack('<l',s)[0]
                pack = ctypes.c_uint32(n).value
                a = points2[i].rgb
                s2 = struct.pack('<f' ,points2[i].rgb)
                n2 = struct.unpack('<l',s2)[0]

                pack2 = ctypes.c_uint32(n2).value
                #pack2 = 0
                diffpack = diffpack + (pack != pack2)
                print pack,pack2
                print pack == pack2

                #print (points[i].x == points2[i].x)
                #print diffx
                #print (points[i].y == points2[i].y)
                #print (points[i].z == points2[i].z)
                #print (points[i].rgb == points2[i].rgb)

            print diffrgb
            print diffx
            print diffy
            print diffz
            print diffpack

        print "...........shape pointcloud new............."
        print len(ptcloud_merged.data)

        #ptcloud_merged.height = self.ptcloud_brown.height
        #ptcloud_merged.height = 1
        #ptcloud_merged.width = self.ptcloud_brown.width
        #ptcloud_merged.width = len(points)
        #ptcloud_merged.point_step = 20
        #ptcloud_merged.row_step = 20*len(points)
        #ptcloud_merged.is_bigendian = self.ptcloud_brown.is_bigendian
        #ptcloud_merged.point_step = self.ptcloud_brown.point_step
        #ptcloud_merged.row_step = self.ptcloud_brown.row_step

        return ptcloud_merged,ptcloud_merged_NaN


if __name__ == "__main__":
    main()