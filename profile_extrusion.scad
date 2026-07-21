// Standalone render of the edge profile replica.
// Aquarium lid modular edge — see edgereplica.scad for options.
include <edgereplica.scad>

/* [Demo selection] */
demo_mode = "default"; // "default" | "cord_hole" | "cord_under" | "ingress" | "combo"

if (demo_mode == "default")
    edgereplica(length = edge_default_length);

if (demo_mode == "cord_hole")
    edgereplica(
        length = 90,
        cord_hole = true,
        cord_hole_inner_d = 6,
        cord_hole_pos = "middle"
    );

if (demo_mode == "cord_under")
    edgereplica(
        length = 90,
        cord_under = true,
        cord_under_gap_len = 25
    );

if (demo_mode == "ingress")
    edgereplica(
        length = 120,
        lid_ingress = true,
        ingress_depth = 30,
        ingress_length = 40,
        ingress_remove_right_rim = true
    );

if (demo_mode == "combo")
    edgereplica(
        length = 150,
        stem_gripper_sides = 2,
        cord_hole = true,
        cord_hole_inner_d = 5,
        cord_hole_pos = "left",
        cord_under = true,
        cord_under_gap_len = 20,
        lid_ingress = true,
        ingress_depth = 28,
        ingress_length = 35,
        ingress_remove_right_rim = true
    );
