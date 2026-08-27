// Standalone render of the rim piece assembly.
// See rim_piece_assembly.scad header for full option reference.
include <rim_piece_assembly.scad>

/* [Demo selection] */
demo_mode = "default";
// "default" | "male_both" | "female_both" | "start_male_finish_female"
// | "start_female_finish_male" | "corner_end" | "rim_corner" | "ingress"
// | "combo" | "rim_corner_ingress_a" | "rim_corner_ingress_b"

if (demo_mode == "default")
    rim_piece_assembly(length = edge_default_length);

if (demo_mode == "male_both")
    rim_piece_assembly(length = 90, edge_join_ends = 2);

if (demo_mode == "female_both")
    rim_piece_assembly(length = 90, edge_join_ends = 4);

if (demo_mode == "start_male_finish_female")
    rim_piece_assembly(length = 90, edge_join_ends = 1);

if (demo_mode == "start_female_finish_male")
    rim_piece_assembly(length = 90, edge_join_ends = 3);

if (demo_mode == "corner_end")
    rim_piece_assembly(
        length = 120,
        edge_join_ends = 1,
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
        ingress_length = 70
    );

if (demo_mode == "combo")
    rim_piece_assembly(
        length = 200,
        edge_join_ends = 2,
        cord_hole = true,
        cord_hole_pos = "left",
        lid_ingress = true,
        ingress_depth = 28,
        ingress_length = 70
    );

if (demo_mode == "rim_corner_ingress_a")
    rim_corner_assembly(
        length_a = 160,
        length_b = 100,
        join_b = 2,
        cord_hole = true,
        cord_hole_pos = "left",
        cord_hole_on = "a",
        lid_ingress = true,
        ingress_depth = 28,
        ingress_length = 70,
        ingress_on = "a"
    );

if (demo_mode == "rim_corner_ingress_b")
    rim_corner_assembly(
        length_a = 120,
        length_b = 170,
        join_b = 2,
        cord_hole = true,
        cord_hole_pos = "middle",
        cord_hole_on = "b",
        lid_ingress = true,
        ingress_depth = 28,
        ingress_length = 10,
        ingress_on = "b"
    );
