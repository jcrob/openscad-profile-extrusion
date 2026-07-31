// Standalone render of the rim piece assembly.
// See rim_piece_assembly.scad header for full option reference.
include <rim_piece_assembly.scad>

/* [Demo selection] */
demo_mode = "default";
// "default" | "male_join" | "female_join" | "both_female"
// | "corner_end" | "rim_corner" | "ingress" | "combo"

if (demo_mode == "default")
    rim_piece_assembly(length = edge_default_length);

if (demo_mode == "male_join")
    rim_piece_assembly(
        length = 90,
        edge_join_ends = 2,
        edge_join_sex = "male"
    );

if (demo_mode == "female_join")
    rim_piece_assembly(
        length = 90,
        edge_join_ends = 2,
        edge_join_sex = "female"
    );

if (demo_mode == "both_female")
    rim_piece_assembly(length = 90, edge_join_ends = 4);

if (demo_mode == "corner_end")
    rim_piece_assembly(
        length = 120,
        edge_join_ends = 1,
        edge_join_sex = "male",
        cornerpiecenum = 3
    );

if (demo_mode == "rim_corner")
    rim_corner_assembly(
        length_a = 80,
        length_b = 60,
        join_a = 1,
        join_b = 2
    );

if (demo_mode == "ingress")
    rim_piece_assembly(
        length = 150,
        lid_ingress = true,
        ingress_depth = 30,
        ingress_length = 40
    );

if (demo_mode == "combo")
    rim_piece_assembly(
        length = 200,
        edge_join_ends = 2,
        edge_join_sex = "male",
        cord_hole = true,
        cord_hole_pos = "left",
        lid_ingress = true,
        ingress_depth = 28,
        ingress_length = 35
    );
