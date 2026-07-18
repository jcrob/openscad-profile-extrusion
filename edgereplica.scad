// Edge profile replica — extruded polygon from dimensioned sketch
// Units: millimeters
//
// Include this file to reuse edge_* dimensions and module edgereplica().
// Standalone render: open profile_extrusion.scad (calls edgereplica).

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

// Cross-section in XY (top at y=0, stem in -Y), extruded along Z.
module edgereplica(length = edge_default_length) {
    linear_extrude(height = length, convexity = 4)
        polygon(points = edge_profile_points);
}

// Stem half-width at a depth below the underside of the top bar.
// depth_below_underside = 0 at stem root, edge_overall_height - edge_left_flat_t at tip.
function edge_stem_half_width_at(depth_below_underside) =
    let (
        max_depth = edge_overall_height - edge_left_flat_t,
        t = max_depth <= 0 ? 0 : depth_below_underside / max_depth,
        half_root = edge_stem_root_w / 2,
        half_tip  = edge_stem_tip_w / 2
    )
    half_root + t * (half_tip - half_root);
