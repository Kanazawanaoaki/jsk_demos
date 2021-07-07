# cf. http://www.open3d.org/docs/release/tutorial/Basic/mesh.html

import copy
import numpy as np
import open3d as o3d

if __name__ == "__main__":

    print("Testing mesh in open3d ...")
    mesh = o3d.io.read_triangle_mesh("../stl/iemon_merged_lr.stl")
    print(mesh)
    print(np.asarray(mesh.vertices))
    print(np.asarray(mesh.triangles))
    print("")

    print("Try to render a mesh with normals (exist: " +
          str(mesh.has_vertex_normals()) + ") and colors (exist: " +
          str(mesh.has_vertex_colors()) + ")")
    o3d.visualization.draw_geometries([mesh])
