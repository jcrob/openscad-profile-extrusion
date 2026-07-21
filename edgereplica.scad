// Edge profile replica — extruded polygon from dimensioned sketch
// Units: millimeters
//
// Include this file to reuse edge_* dimensions and module edgereplica().
// Standalone render: open profile_extrusion.scad (calls edgereplica).
//
// edgereplica(length, stem_gripper_sides)
//   stem_gripper_sides = 0  none (default — existing callers unchanged)
//                      = 1  grippers + top-ridge seat at Z start
//                      = 2  same at both extrusion ends

/* [Edge profile dimensions] */
edge_top_width             = 13.8;
edge_overall_height        = 26.8;
edge_top_thickness         = 1.9;
edge_left_flange_h         = 11.0;
edge_left_flat_w           = 3.4;   // flange inner top → stem root left
edge_stem_root_w           = 3.8;
edge_stem_tip_w            = 0.95;
edge_left_flange_t         = edge_top_thickness;
edge_left_flange_tip_t     = 1.16;
edge_left_flange_tip_right = 3.2;   // bends toward stem
edge_right_segment_tip_t   = 1.16;
edge_left_flat_t           = edge_top_thickness;
edge_right_segment_root_t  = edge_left_flat_t;
edge_default_length        = 50;

/* [Optional end stem grippers — same idea as cornerpiece] */
edge_gripper_width           = 3.0;
edge_gripper_height          = edge_left_flange_h;
edge_gripper_len             = 15.0;  // how far each end assembly extends in Z
edge_gripper_entry_clearance = 0.20;
edge_gripper_lip_taper       = 0.5;   // thicker toward the edge body on each bar

/* [Top-ridge seat on ends that have stem grippers] */
// Cube on the top-width segment; mating top ridge slides into the slot
// between this cube, the side grippers, and the stem.
edge_top_ridge_grip_h        = 5.0;   // height above top surface (y=0)
edge_top_ridge_slot_w        = 3.0;   // slide slot width for mating ridge
edge_top_ridge_grip_inset_x  = 0.0;   // inset from profile x = top_width
edge_gripper_body_overlap    = 0.05;  // merge end assemblies into extruded body
edge_gripper_body_overlap_z  = 5;

edge_left_flange_tip_left = edge_left_flange_tip_right - edge_left_flange_tip_t;
edge_stem_root_left       = edge_left_flange_t + edge_left_flat_w;
edge_stem_root_right      = edge_stem_root_left + edge_stem_root_w;
edge_tip_center_x         = edge_stem_root_left + edge_stem_root_w / 2;
edge_tip_left_x           = edge_tip_center_x - edge_stem_tip_w / 2;
edge_tip_right_x          = edge_tip_center_x + edge_stem_tip_w / 2;

edge_profile_points = [
    [0,                           0],
    [edge_left_flange_tip_left,  -edge_left_flange_h],
    [edge_left_flange_tip_right, -edge_left_flange_h],
    [edge_left_flange_t,         -edge_left_flat_t],
    [edge_stem_root_left,        -edge_left_flat_t],
    [edge_tip_left_x,            -edge_overall_height],
    [edge_tip_right_x,           -edge_overall_height],
    [edge_stem_root_right,       -edge_right_segment_root_t],
    [edge_top_width,             -edge_right_segment_tip_t],
    [edge_top_width,              0],
];

edge_gripper_gap_entry = edge_stem_root_w + edge_gripper_entry_clearance;

// Stem half-width at a depth below the underside of the top bar.
function edge_stem_half_width_at(depth_below_underside) =
    let (
        max_depth = edge_overall_height - edge_left_flat_t,
        t = max_depth <= 0 ? 0 : depth_below_underside / max_depth,
        half_root = edge_stem_root_w / 2,
        half_tip  = edge_stem_tip_w / 2
    )
    half_root + t * (half_tip - half_root);

// ---------------------------------------------------------------------------
// Stem gripper bars (native edgereplica frame: stem in -Y, extrusion in +Z)
// ---------------------------------------------------------------------------

// Bar length along +Z. Thicker toward stem at the body end (z = 0 local).
// toward_stem_sign: +1 grows in +X, -1 grows in -X.
module edge_tapered_stem_gripper_bar(bar_len, bar_width, bar_height, lip_taper, toward_stem_sign = 1) {
    // Extend slightly above y=0 so the bar unions into the top face cleanly.
    h = bar_height + edge_gripper_body_overlap;
    hull() {
        translate([toward_stem_sign < 0 ? -lip_taper : 0, -bar_height, 0])
            cube([bar_width + lip_taper, h, 0.02]);
        translate([0, -bar_height, bar_len - 0.02])
            cube([bar_width, h, 0.02]);
    }
}

// Pair of bars straddling the stem, same layout idea as cornerpiece.
module edge_stem_gripper_pair(z_pos = 0) {
    center_axis   = edge_tip_center_x;
    neg_outer_far = center_axis - edge_gripper_gap_entry / 2 - edge_gripper_width;
    pos_inner_far = center_axis + edge_gripper_gap_entry / 2;

    translate([0, -edge_top_thickness, z_pos]) {
        translate([neg_outer_far, 0, 0])
            edge_tapered_stem_gripper_bar(
                edge_gripper_len, edge_gripper_width, edge_gripper_height,
                edge_gripper_lip_taper, toward_stem_sign = 1
            );
        translate([pos_inner_far, 0, 0])
            edge_tapered_stem_gripper_bar(
                edge_gripper_len, edge_gripper_width, edge_gripper_height,
                edge_gripper_lip_taper, toward_stem_sign = -1
            );
    }
}

// Cube on the top-width segment (+Y above y=0). A slide slot between the stem
// root and this cube lets another piece's top ridge enter — grip between top
// seat, side stem grippers, and the stem.
module edge_top_ridge_grip_cube(z_pos = 0) {
    cube_left_x  = edge_stem_root_right + edge_top_ridge_slot_w;
    cube_right_x = edge_top_width - edge_top_ridge_grip_inset_x;
    cube_w       = cube_right_x - cube_left_x;

    if (cube_w > 0)
        // Sink slightly into the top face so the seat unions into the body.
        translate([0, -edge_gripper_body_overlap, z_pos])
            cube([edge_top_width, cube_w, edge_gripper_len]);
}

// Full end assembly: side stem grippers + top-ridge seat.
module edge_end_stem_gripper_assembly(z_pos = -2) {
    edge_stem_gripper_pair(z_pos = z_pos);
    edge_top_ridge_grip_cube(z_pos = z_pos);
}

// Cross-section in XY (top at y=0, stem in -Y), extruded along Z.
// stem_gripper_sides: 0 = none, 1 = start end, 2 = both ends.
module edgereplica(length = edge_default_length, stem_gripper_sides = 0) {
    assert(stem_gripper_sides == 0 || stem_gripper_sides == 1 || stem_gripper_sides == 2,
        "stem_gripper_sides must be 0, 1, or 2");

    union() {
        linear_extrude(height = length, convexity = 4)
            polygon(points = edge_profile_points);

        if (stem_gripper_sides >= 1)
            edge_end_stem_gripper_assembly(
                z_pos = -edge_gripper_len + edge_gripper_body_overlap + edge_gripper_body_overlap_z
            );

        if (stem_gripper_sides >= 2)
            edge_end_stem_gripper_assembly(
                z_pos = length - edge_gripper_body_overlap - edge_gripper_body_overlap_z
            );
    }
}
