import rospy
from jsk_recognition_msgs.srv import TransformScreenpoint

def call_screenpoint_service(x, y):
    rospy.wait_for_service('/pointcloud_screenpoint_nodelet/screen_to_point')

    try:
        screenpoint_service = rospy.ServiceProxy('/pointcloud_screenpoint_nodelet/screen_to_point', TransformScreenpoint)
        response = screenpoint_service(x, y, False)
        return response.point
    except rospy.ServiceException as e:
        print("Service call failed:", str(e))
        return None

if __name__ == "__main__":
    # 初期化
    rospy.init_node('screenpoint_client')

    # 指定されたx, y座標のリスト now points
    coordinates = [[395.0, 351.0], [380.0, 327.0], [198.0, 430.0], [394.0, 325.0], [356.0, 365.0], [486.0, 313.0], [438.0, 328.0], [369.0, 340.0], [450.0, 424.0], [366.0, 442.0]]
    # coordinates = [(378, 328), (277, 390), (391, 325), (487, 409), (313, 444), (353, 365), (473, 363), (193, 410), (338, 431), (209, 410)]

    # 結果を保存するリスト
    results = []

    hoge = []
    for x, y in coordinates:
        point = call_screenpoint_service(x, y)
        print(point)
        if point:
            results.append(point)
            # import ipdb
            # ipdb.set_trace()
            hoge.append([point.x, point.y, point.z])

    # 結果の表示
    print(coordinates)
    print(hoge)
    for i, point in enumerate(results):
        print(f"Point {i+1}: ({point.x}, {point.y}, {point.z})")
