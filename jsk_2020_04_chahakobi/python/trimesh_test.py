import open3d as o3d
import trimesh
import numpy as np
import sys

file_name = "../pcd/kettle_attention.pcd"
if len(sys.argv)>=2:
    file_name = sys.argv[1]

print("Load a ply point cloud, print it, and render it")
pcd = o3d.io.read_point_cloud(file_name)
pcd.estimate_normals()

# estimate radius for rolling ball
distances = pcd.compute_nearest_neighbor_distance()
avg_dist = np.mean(distances)
radius = 1.5 * avg_dist

mesh = o3d.geometry.TriangleMesh.create_from_point_cloud_ball_pivoting(
           pcd,
           o3d.utility.DoubleVector([radius, radius * 2]))

trimesh = trimesh.Trimesh(np.asarray(mesh.vertices), np.asarray(mesh.triangles),
                          vertex_normals=np.asarray(mesh.vertex_normals))
print(trimesh)

export_file = "test.stl"
if len(sys.argv)>=3:
    export_file = sys.argv[2]
trimesh.export(export_file)
