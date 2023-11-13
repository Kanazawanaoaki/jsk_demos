import datetime

import rospy
import cv_bridge
import sensor_msgs.msg


class TopicSubscriber(object):

    def __init__(self,
                 topic_name,
                 cls,
                 one_shot=False,
                 start=True,
                 wait=False,
                 warn_timeout=10.0,
                 hook=None):
        self.hook = hook or []
        self.msg = None
        self.sub = None
        self.warn_timeout = warn_timeout
        self.cls = cls
        self.topic_name = topic_name
        self.one_shot = one_shot

        if start or wait:
            self.subscribe()
        if wait:
            self.wait_message()

    def __del__(self):
        self.unsubscribe()

    def subscribe(self):
        self.msg = None
        self.sub = rospy.Subscriber(
            self.topic_name,
            self.cls,
            callback=self.callback,
            queue_size=1)

    def unsubscribe(self):
        if self.sub is not None:
            self.sub.unregister()
        self.sub = None

    def callback(self, msg):
        for h in self.hook:
            h(msg)
        self.msg = msg
        if self.one_shot:
            self.unsubscribe()

    def wait_message(self):
        rate = rospy.Rate(10)
        start = datetime.datetime.now()
        cur_start = start
        while not rospy.is_shutdown():
            if self.msg is not None:
                break
            rate.sleep()
            cur_time = datetime.datetime.now()
            dt = cur_time - cur_start
            if dt > datetime.timedelta(seconds=self.warn_timeout):
                dt = cur_time - start
                rospy.logwarn('Topic {} not received for {} seconds'.
                              format(self.topic_name, dt))
                cur_start = datetime.datetime.now()

    def wait_new_message(self):
        rate = rospy.Rate(10)
        start = datetime.datetime.now()
        cur_start = start
        ros_start_stamp = rospy.Time.now()
        while not rospy.is_shutdown():
            if self.msg is not None:
                if hasattr(self.msg, 'header'):
                    cur_stamp = self.msg.header.stamp
                else:
                    cur_stamp = rospy.Time.now()
                if (cur_stamp - ros_start_stamp).to_sec() > 0:
                    break
            if self.msg is not None and \
                    (self.msg.header.stamp - ros_start_stamp).to_sec() > 0:
                break
            rate.sleep()
            cur_time = datetime.datetime.now()
            dt = cur_time - cur_start
            if dt > datetime.timedelta(seconds=self.warn_timeout):
                dt = cur_time - start
                rospy.logwarn('Topic {} not received for {} seconds'.
                              format(self.topic_name, dt))
                cur_start = datetime.datetime.now()
        return self.msg


class ImageSubscriber(TopicSubscriber):

    def __init__(self,
                 topic_name,
                 one_shot=False,
                 start=True,
                 wait=False):
        super(ImageSubscriber, self).__init__(
            topic_name,
            sensor_msgs.msg.Image,
            one_shot=one_shot,
            start=start,
            wait=wait)
        self.bridge = cv_bridge.CvBridge()

    @property
    def image(self):
        if self.msg is None:
            return None
        cv_image = self.bridge.imgmsg_to_cv2(self.msg, 'bgr8')
        return cv_image

    def take_image(self, fmt='bgr8'):
        if self.msg is None:
            return None
        cv_image = self.bridge.imgmsg_to_cv2(self.msg, fmt)
        return cv_image
