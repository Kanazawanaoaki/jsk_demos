#!/usr/bin/env python

# cf. http://www.open3d.org/docs/release/tutorial/Basic/pointcloud.html
# cf. http://www.open3d.org/docs/latest/tutorial/Basic/transformation.html

import numpy as np
import open3d as o3d
import copy
import sys


trafo = [[ -1.06587713e-04,  -1.48836837e-04,   9.99999983e-01,   9.49812011e-02],
         [ -2.79428358e-04,   9.99999950e-01,   1.48807048e-04,   8.51618739e-06],
         [ -9.99999955e-01,  -2.79412492e-04,  -1.06629296e-04,  -2.00135879e-02],
         [  0.00000000e+00,   0.00000000e+00,   0.00000000e+00,   1.00000000e+00]]

voxel_size = 0.002

if __name__ == "__main__":

    file1_name = "../pcd/make_iemon_model/iemon_merged_l.pcd"
    file2_name = "../pcd/make_iemon_model/iemon_merged_r.pcd"
        
    print("Load a pcd point cloud, print it, and render it")
    pcd1 = o3d.io.read_point_cloud(file1_name)
    pcd2 = o3d.io.read_point_cloud(file2_name)
    print(pcd1)
    print(np.asarray(pcd1.points))
    # o3d.visualization.draw_geometries([pcd,pcd2])

    # transfrom
    trans_pcd1 = copy.deepcopy(pcd1).transform(trafo)
    # o3d.visualization.draw_geometries([pcd2,trans_pcd1])

    # combine
    pcd_combined = o3d.geometry.PointCloud()
    pcds = [trans_pcd1,pcd2] 
    for point_id in range(len(pcds)):
        pcd_combined += pcds[point_id]
    pcd_combined_down = pcd_combined.voxel_down_sample(voxel_size=voxel_size)
    o3d.io.write_point_cloud("../pcd/make_iemon_model/iemon_combined_model.pcd", pcd_combined_down)
    o3d.visualization.draw_geometries([pcd_combined_down])
