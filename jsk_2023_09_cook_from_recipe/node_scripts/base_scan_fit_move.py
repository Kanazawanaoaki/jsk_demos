import numpy as np
import rospy
import sensor_msgs.msg


def rtheta2xy(rtheta):
    xy = []
    for e in rtheta:
        xy.append([e[0] * np.sin(e[1]), e[0] * np.cos(e[1])])
    return xy


def xy2ab(xy):
    n = len(xy)
    sx, sy = np.sum(xy, axis=0)
    sxx, syy = np.sum(xy * xy, axis=0)
    sxy = np.sum(xy[:, 0] * xy[:, 1])
    a = ((n * sxy) - (sx * sy)) / ((n * sxx) - (sx * sx))
    b = ((sxx * sy) - (sxy * sx)) / ((n * sxx) - (sx * sx))
    return a, b


class MoveWithBaseScan(object):

    def __init__(self, scan_topic_name='/base_scan'):
        self.scan_topic_name = scan_topic_name

        self.laser_msg = None
        self.averages = []
        self.distance_center = None
        self.offset = 0

    def _cb(self, msg):
        base_scan_point_num = 10
        pc = np.array(msg.ranges)
        center_index = len(pc) // 2 - self.offset
        self.distance_center = pc[center_index]
        angle_min = msg.angle_min
        angle_inc = msg.angle_increment
        front_pc = pc[center_index - base_scan_point_num:
                      center_index + base_scan_point_num]
        rtheta = []
        for i in range(len(front_pc)):
            rtheta.append((front_pc[i],
                           angle_min + (((center_index - base_scan_point_num) + i)
                                        * angle_inc)))
        xy = np.array(rtheta2xy(rtheta))
        self.averages.append(xy2ab(xy))

    def subscribe(self):
        self.sub = rospy.Subscriber(self.scan_topic_name,
                                    sensor_msgs.msg.LaserScan,
                                    callback=self._cb,
                                    queue_size=1)

    def unsubscribe(self):
        self.sub.unregister()

    def get_params(self, duration=1.0, offset=0):
        self.distance_center = None
        self.offset = offset
        self.averages = []
        self.subscribe()
        start_time = rospy.Time.now()
        rate = rospy.Rate(10)
        while not rospy.is_shutdown() \
              and (rospy.Time.now() - start_time).to_sec() < duration:
            rate.sleep()
        self.unsubscribe()
        if len(self.averages) == 0:
            raise ValueError('Could not get base_topic. Please check {} publishd'.format(self.scan_topic_name))
        averages = self.averages
        distance_center = self.distance_center
        average = np.array(averages)[:, 0].sum() / len(averages)
        diff_x = distance_center * (1.0 - np.cos(np.arctan(average)))
        diff_y = distance_center * (np.sin(np.arctan(average)))
        diff_angle = np.arctan(- average)
        rospy.loginfo('distance: {}'.format(average))
        rospy.loginfo('move to (x, y, deg) = {} {} {}'.format(diff_x, diff_y, np.rad2deg(diff_angle)))
        return diff_x, diff_y, diff_angle

    def move_with_base_scan(self, duration=1.0, offset=0):
        diff_x, diff_y, diff_angle = self.get_params(
            duration=duration, offset=offset)
        print(diff_x, diff_y, diff_angle)
        # self.interface.go_pos(yaw=diff_angle)

if __name__ == '__main__':
    from skrobot_hsr.hsrb import HSRB
    from skrobot_hsr.ros.hsrb import HSRBROSRobotInterface

    rospy.init_node('move_utils_sample')
    # r = HSRB()
    # ri = HSRBROSRobotInterface(r)
    move = MoveWithBaseScan('/base_scan')
    move.move_with_base_scan()
