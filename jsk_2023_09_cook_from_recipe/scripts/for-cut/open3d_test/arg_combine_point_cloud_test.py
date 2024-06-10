import open3d as o3d
import numpy as np
import argparse
import os

def process_binary_pcd(pcd):
    # 点群のnumpy配列を取得
    points = np.asarray(pcd.points)
    colors = np.asarray(pcd.colors)

    # 有効なポイントのみをフィルタリング（NaNを含まないポイント）
    # valid_points = points[np.isfinite(points).all(axis=1)]
    valid_indices = np.isfinite(points).all(axis=1) & np.isfinite(colors).all(axis=1)
    valid_points = points[valid_indices]
    valid_colors = colors[valid_indices]


    # 有効なポイントを新しい点群に設定
    valid_pcd = o3d.geometry.PointCloud()
    valid_pcd.points = o3d.utility.Vector3dVector(valid_points)
    valid_pcd.colors = o3d.utility.Vector3dVector(valid_colors)

    # 新しい点群情報を出力
    print(f"Valid PointCloud with {len(valid_pcd.points)} points.")
    print(f"Bounding box: {valid_pcd.get_min_bound()}, {valid_pcd.get_max_bound()}")
    print(f"Center: {valid_pcd.get_center()}")

    return valid_pcd

def load_point_clouds(folder_path, voxel_size=0.0):
    pcds = []
    for filename in os.listdir(folder_path):
        if filename.endswith(".pcd"):
            pcd_file_path = os.path.join(folder_path, filename)
            pcd = o3d.io.read_point_cloud(pcd_file_path)
            valid_pcd = process_binary_pcd(pcd)
            pcd_down = valid_pcd.voxel_down_sample(voxel_size=voxel_size)
            print(f"Visualizing: {pcd_file_path}")
            pcds.append(pcd_down)
    return pcds

def pairwise_registration(source, target):
    print("Apply point-to-plane ICP")
    target.estimate_normals(search_param=o3d.geometry.KDTreeSearchParamHybrid(radius=0.1, max_nn=30)) ## << Add this line
    icp_coarse = o3d.pipelines.registration.registration_icp(
        source, target, max_correspondence_distance_coarse, np.identity(4),
        o3d.pipelines.registration.TransformationEstimationPointToPlane())
    icp_fine = o3d.pipelines.registration.registration_icp(
        source, target, max_correspondence_distance_fine,
        icp_coarse.transformation,
        o3d.pipelines.registration.TransformationEstimationPointToPlane())
    transformation_icp = icp_fine.transformation
    information_icp = o3d.pipelines.registration.get_information_matrix_from_point_clouds(
        source, target, max_correspondence_distance_fine,
        icp_fine.transformation)
    return transformation_icp, information_icp


def full_registration(pcds, max_correspondence_distance_coarse,
                      max_correspondence_distance_fine):
    pose_graph = o3d.pipelines.registration.PoseGraph()
    odometry = np.identity(4)
    pose_graph.nodes.append(o3d.pipelines.registration.PoseGraphNode(odometry))
    n_pcds = len(pcds)
    for source_id in range(n_pcds):
        for target_id in range(source_id + 1, n_pcds):
            transformation_icp, information_icp = pairwise_registration(
                pcds[source_id], pcds[target_id])
            print("Build o3d.pipelines.registration.PoseGraph")
            if target_id == source_id + 1:  # odometry case
                odometry = np.dot(transformation_icp, odometry)
                pose_graph.nodes.append(
                    o3d.pipelines.registration.PoseGraphNode(
                        np.linalg.inv(odometry)))
                pose_graph.edges.append(
                    o3d.pipelines.registration.PoseGraphEdge(source_id,
                                                             target_id,
                                                             transformation_icp,
                                                             information_icp,
                                                             uncertain=False))
            else:  # loop closure case
                pose_graph.edges.append(
                    o3d.pipelines.registration.PoseGraphEdge(source_id,
                                                             target_id,
                                                             transformation_icp,
                                                             information_icp,
                                                             uncertain=True))
    return pose_graph

parser = argparse.ArgumentParser(description="Open a point cloud file using Open3D")
parser.add_argument("folder", type=str, help="Path to the folder containing PCD files.")
args = parser.parse_args()


voxel_size = 0.02
pcds_down = load_point_clouds(args.folder, voxel_size)
o3d.visualization.draw_geometries(pcds_down,
                                  # zoom=0.3412,
                                  # front=[0.4257, -0.2125, -0.8795],
                                  # lookat=[2.6172, 2.0475, 1.532],
                                  # up=[-0.0694, -0.9768, 0.2024]
)

print("Full registration ...")
max_correspondence_distance_coarse = voxel_size * 15
max_correspondence_distance_fine = voxel_size * 1.5
with o3d.utility.VerbosityContextManager(
        o3d.utility.VerbosityLevel.Debug) as cm:
    pose_graph = full_registration(pcds_down,
                                   max_correspondence_distance_coarse,
                                   max_correspondence_distance_fine)

print("Optimizing PoseGraph ...")
option = o3d.pipelines.registration.GlobalOptimizationOption(
    max_correspondence_distance=max_correspondence_distance_fine,
    edge_prune_threshold=0.25,
    reference_node=0)
with o3d.utility.VerbosityContextManager(
        o3d.utility.VerbosityLevel.Debug) as cm:
    o3d.pipelines.registration.global_optimization(
        pose_graph,
        o3d.pipelines.registration.GlobalOptimizationLevenbergMarquardt(),
        o3d.pipelines.registration.GlobalOptimizationConvergenceCriteria(),
        option)

pcds = load_point_clouds(args.folder, voxel_size)
pcd_combined = o3d.geometry.PointCloud()
for point_id in range(len(pcds)):
    pcds[point_id].transform(pose_graph.nodes[point_id].pose)
    pcd_combined += pcds[point_id]
pcd_combined_down = pcd_combined.voxel_down_sample(voxel_size=voxel_size)
o3d.io.write_point_cloud("test_multiway_registration.pcd", pcd_combined_down)
o3d.visualization.draw_geometries([pcd_combined_down],
                                  # zoom=0.3412,
                                  # front=[0.4257, -0.2125, -0.8795],
                                  # lookat=[2.6172, 2.0475, 1.532],
                                  # up=[-0.0694, -0.9768, 0.2024]
)
