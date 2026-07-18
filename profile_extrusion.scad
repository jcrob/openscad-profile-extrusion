// Standalone render of the edge profile replica.
include <edgereplica.scad>

// Default: no end grippers (same as cornerpiece call).
edgereplica(length = edge_default_length);

// Uncomment to preview one or both end stem-gripper assemblies:
// translate([0, 0, edge_default_length + 20])
//     edgereplica(length = edge_default_length, stem_gripper_sides = 1);
// translate([0, 0, 2 * (edge_default_length + 20)])
//     edgereplica(length = edge_default_length, stem_gripper_sides = 2);
