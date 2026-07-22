// Edge profile replica — extruded polygon from dimensioned sketch
// Units: millimeters
//
// Aquarium lid modular edge: right rim sits on glass; left flange + stem
// take spline for mesh screen. Optional features for cord pass-throughs
// and lid ingress bays.
//
// Include this file to reuse edge_* dimensions and module edgereplica().
// Standalone render: open profile_extrusion.scad (calls edgereplica).
//
// edgereplica(length, stem_gripper_sides, ...)
//   stem_gripper_sides = 0|1|2  end gripper assemblies (default 0)
//   cord_hole / cord_under / lid_ingress — see parameters below (all default off)

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
edge_gripper_len             = 15.0;
edge_gripper_entry_clearance = 0.20;
edge_gripper_lip_taper       = 0.5;

/* [Top-ridge seat on ends that have stem grippers] */
edge_top_ridge_grip_h        = 5.0;
edge_top_ridge_slot_w        = 3.0;
edge_top_ridge_grip_inset_x  = 0.0;
edge_gripper_body_overlap    = 0.05;
edge_gripper_body_overlap_z  = 5;

/* [1) Circle cord hole — flange-side boss continuous with rim] */
edge_cord_hole_enable        = false;
edge_cord_hole_inner_d       = 6.0;   // bore when enabled
edge_cord_hole_outer_d       = 6.0;   // constant radial wall thickness (OD = ID + this)
edge_cord_hole_pos           = "middle"; // "left" 1/3 | "middle" 1/2 | "right" 2/3

/* [2) Cord under — mid gap: keep top, shorten flange+stem] */
edge_cord_under_enable       = false;
edge_cord_under_gap_len      = 20.0;
edge_cord_under_keep_below   = 5.0;   // flange/stem kept this far below rim bottom

/* [3) Lid ingress — U bay of flange+stem edges for spline + pass-through] */
edge_ingress_enable          = false;
edge_ingress_depth           = 30.0;  // "left" dim — bay depth (flange/interior direction)
edge_ingress_length          = 40.0;  // bay width along main edge (Z)
edge_ingress_remove_right_rim = false; // mount: strip glass rim on ingress segments
edge_ingress_z_center        = undef; // undef → centered on length

// ---------------------------------------------------------------------------
// Derived profile geometry
// ---------------------------------------------------------------------------
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

// Flange + stem only (no glass-sitting right rim) — for ingress mount option
edge_profile_points_no_right_rim = [
    [0,                           0],
    [edge_left_flange_tip_left,  -edge_left_flange_h],
    [edge_left_flange_tip_right, -edge_left_flange_h],
    [edge_left_flange_t,         -edge_left_flat_t],
    [edge_stem_root_left,        -edge_left_flat_t],
    [edge_tip_left_x,            -edge_overall_height],
    [edge_tip_right_x,           -edge_overall_height],
    [edge_stem_root_right,       -edge_right_segment_root_t],
    [edge_stem_root_right,        0],
];

edge_gripper_gap_entry = edge_stem_root_w + edge_gripper_entry_clearance;

function edge_stem_half_width_at(depth_below_underside) =
    let (
        max_depth = edge_overall_height - edge_left_flat_t,
        t = max_depth <= 0 ? 0 : depth_below_underside / max_depth,
        half_root = edge_stem_root_w / 2,
        half_tip  = edge_stem_tip_w / 2
    )
    half_root + t * (half_tip - half_root);

function edge_cord_hole_z(length, pos) =
    pos == "left"  ? length / 3 :
    pos == "right" ? 2 * length / 3 :
                     length / 2;

function edge_select_profile(remove_right_rim) =
    remove_right_rim ? edge_profile_points_no_right_rim : edge_profile_points;

// ---------------------------------------------------------------------------
// Stem gripper bars (native frame: stem in -Y, extrusion in +Z)
// ---------------------------------------------------------------------------

module edge_tapered_stem_gripper_bar(bar_len, bar_width, bar_height, lip_taper, toward_stem_sign = 1) {
    h = bar_height + edge_gripper_body_overlap;
    hull() {
        translate([toward_stem_sign < 0 ? -lip_taper : 0, -bar_height, 0])
            cube([bar_width + lip_taper, h, 0.02]);
        translate([0, -bar_height, bar_len - 0.02])
            cube([bar_width, h, 0.02]);
    }
}

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

module edge_top_ridge_grip_cube(z_pos = 0) {
    cube_left_x  = edge_stem_root_right + edge_top_ridge_slot_w;
    cube_right_x = edge_top_width - edge_top_ridge_grip_inset_x;
    cube_w       = cube_right_x - cube_left_x;

    if (cube_w > 0)
        translate([0, -edge_gripper_body_overlap, z_pos])
            cube([edge_top_width, cube_w, edge_gripper_len]);
}

module edge_end_stem_gripper_assembly(z_pos = -2) {
    edge_stem_gripper_pair(z_pos = z_pos);
    edge_top_ridge_grip_cube(z_pos = z_pos);
}

// ---------------------------------------------------------------------------
// 1) Circle cord hole — flat cylinder continuous with rim on flange side
// ---------------------------------------------------------------------------

module edge_cord_hole_feature(length, inner_d, pos) {
    zc = edge_cord_hole_z(length, pos);
    // Axis along Y so the flat faces are continuous with rim top/bottom.
    // outer_d is constant radial wall thickness; OD = ID + outer_d.
    translate([-inner_d / 2, -edge_top_thickness, zc])
    rotate([-90, 0, 0])
    difference() {
        cylinder(d = inner_d + edge_cord_hole_outer_d, h = edge_top_thickness, $fn = 48);
        translate([0, 0, -0.01])
            cylinder(d = inner_d, h = edge_top_thickness + 0.02, $fn = 48);
    }
}

// ---------------------------------------------------------------------------
// 2) Cord under — keep top ridge; shorten flange+stem in a mid gap
// ---------------------------------------------------------------------------

module edge_cord_under_cut(length, gap_len, keep_below) {
    z0 = (length - gap_len) / 2;
    cut_top_y = -(edge_top_thickness + keep_below);
    cut_h = edge_overall_height + cut_top_y + 0.02; // from tip up to cut_top_y
    if (cut_h > 0 && gap_len > 0)
        translate([-0.01, -edge_overall_height - 0.01, z0])
            cube([edge_stem_root_right + 0.02, cut_h, gap_len]);
}

// ---------------------------------------------------------------------------
// 3) Lid ingress — U bay with continuous main rim and outer flange path
//
// Blue: main glass rim stays a solid continuous edge (not miter-notched).
// Red:  left flange+stem follows the outer perimeter of the U.
// Black: no flange on the bay-inner side at the main↔arm junctions.
// All four U corners are 45° miters sized from ingress + profile parameters.
// ---------------------------------------------------------------------------

/* [Lid ingress joints] */
edge_ingress_joint = 0.1; // volumetric overlap so miter faces fuse

function edge_ingress_profile_w(remove_right_rim) =
    remove_right_rim ? edge_stem_root_right : edge_top_width;

// Half-space cutter size from the live ingress span (not magic constants).
function edge_miter_span(depth, bay_len) =
    2 * (depth + bay_len + edge_top_width + edge_overall_height);

module edge_profile_extrude(seg_len, remove_right_rim = false) {
    linear_extrude(height = seg_len, convexity = 4)
        polygon(points = edge_select_profile(remove_right_rim));
}

// 45° half-space cutter in the XZ (top) plane through (cx, cz).
// rot_y = 45  → plane (x-cx)+(z-cz)=0
// rot_y = -45 → plane (x-cx)-(z-cz)=0
// flip=false removes the local +Z half; flip=true removes the other.
// pull keeps a thin sliver past the plane so mating miters overlap.
module edge_miter_slab(cx, cz, rot_y, flip = false, pull = edge_ingress_joint, span = 0) {
    big = (span > 0 ? span : edge_miter_span(edge_ingress_depth, edge_ingress_length))
        + edge_default_length;
    z_off = (flip ? -big : 0) + (flip ? -pull : pull);
    translate([cx, -edge_overall_height - edge_ingress_joint, cz])
    rotate([0, rot_y, 0])
    translate([-big / 2, 0, z_off])
        cube([big, edge_overall_height + edge_top_ridge_grip_h + edge_top_width, big]);
}

// Main-run segment along +Z
module edge_run_z(z0, seg_len, remove_right_rim = false) {
    if (seg_len > 0.01)
        translate([0, 0, z0])
            edge_profile_extrude(seg_len, remove_right_rim);
}

// Perpendicular run along -X. Flange at z_flange; rim on the other Z side.
module edge_run_neg_x(z_flange, seg_len, rim_toward_neg_z = true, remove_right_rim = false) {
    if (seg_len > 0.01) {
        if (rim_toward_neg_z) {
            translate([-seg_len, 0, z_flange])
            rotate([0, 90, 0])
                edge_profile_extrude(seg_len, remove_right_rim);
        } else {
            translate([0, 0, z_flange])
            rotate([0, -90, 0])
                edge_profile_extrude(seg_len, remove_right_rim);
        }
    }
}

// Open the bay through the main edge: keep glass rim (blue), remove flange+stem.
// Leave a thin flange lip at z0/z1 so side-arm miters volumetrically overlap the main.
module edge_ingress_bay_opening_cut(z0, z1, depth, bay_len, remove_right_rim) {
    mw = edge_ingress_profile_w(remove_right_rim);
    cut_w = min(edge_top_width - edge_ingress_joint,
                max(edge_stem_root_right, mw) + edge_ingress_joint);

    translate([-edge_ingress_joint, -edge_overall_height - edge_ingress_joint,
               z0 + edge_ingress_joint])
        cube([cut_w + edge_ingress_joint,
              edge_overall_height + 2 * edge_ingress_joint,
              (z1 - z0) - 2 * edge_ingress_joint]);
}

// Near arm: flange on outer red path at z=z0; rim into bay (+Z). Miters at main + back.
module edge_ingress_arm_near(z0, depth, bay_len, remove_right_rim) {
    mw   = edge_ingress_profile_w(remove_right_rim);
    span = edge_miter_span(depth, bay_len);
    difference() {
        // Stock past main (x>0) and past back (x<-depth) for 45° cuts
        translate([mw, 0, 0])
            edge_run_neg_x(z0, depth + 2 * mw, false, remove_right_rim);
        // Main corner (0,z0): diagonal into bay — complementary to main lip
        edge_miter_slab(0, z0, -45, flip = true, span = span);
        // Back corner (-depth, z0)
        edge_miter_slab(-depth, z0, -45, flip = false, span = span);
    }
}

// Far arm: flange on outer red path at z=z1; rim into bay (-Z). Miters at main + back.
module edge_ingress_arm_far(z1, depth, bay_len, remove_right_rim) {
    mw   = edge_ingress_profile_w(remove_right_rim);
    span = edge_miter_span(depth, bay_len);
    difference() {
        translate([mw, 0, 0])
            edge_run_neg_x(z1, depth + 2 * mw, true, remove_right_rim);
        // Main corner (0,z1): complementary to main lip
        edge_miter_slab(0, z1, 45, flip = false, span = span);
        // Back corner (-depth, z1)
        edge_miter_slab(-depth, z1, 45, flip = true, span = span);
    }
}

// Back wall: flange on outer red path at x=-depth; rim into bay (+X).
module edge_ingress_back(z0, z1, depth, bay_len, remove_right_rim) {
    mw   = edge_ingress_profile_w(remove_right_rim);
    span = edge_miter_span(depth, bay_len);
    difference() {
        translate([-depth, 0, 0])
            edge_run_z(z0 - mw, (z1 - z0) + 2 * mw, remove_right_rim);
        // Complementary keep-sides vs arms
        edge_miter_slab(-depth, z0, -45, flip = true, span = span);
        edge_miter_slab(-depth, z1, 45, flip = false, span = span);
    }
}

module edge_lid_ingress(length, depth, bay_len, remove_right_rim = false, z_center) {
    zc = is_undef(z_center) ? length / 2 : z_center;
    z0 = zc - bay_len / 2;
    z1 = zc + bay_len / 2;
    mw = edge_ingress_profile_w(remove_right_rim);

    assert(z0 >= mw && z1 <= length - mw,
        "lid ingress bay needs room for flange miters within edge length");

    union() {
        // Continuous main edge — solid right rim through the bay (blue)
        difference() {
            edge_run_z(0, length, false);
            edge_ingress_bay_opening_cut(z0, z1, depth, bay_len, remove_right_rim);
        }

        edge_ingress_arm_near(z0, depth, bay_len, remove_right_rim);
        edge_ingress_arm_far(z1, depth, bay_len, remove_right_rim);
        edge_ingress_back(z0, z1, depth, bay_len, remove_right_rim);
    }
}

// ---------------------------------------------------------------------------
// Main module
// ---------------------------------------------------------------------------

// Cross-section in XY (top at y=0, stem in -Y), extruded along Z.
module edgereplica(
    length = edge_default_length,
    stem_gripper_sides = 0,
    // 1) circle cord hole
    cord_hole = undef,
    cord_hole_inner_d = undef,
    cord_hole_pos = undef,
    // 2) cord under
    cord_under = undef,
    cord_under_gap_len = undef,
    // 3) lid ingress
    lid_ingress = undef,
    ingress_depth = undef,
    ingress_length = undef,
    ingress_remove_right_rim = undef,
    ingress_z_center = undef
) {
    // Resolve options (module args override file defaults)
    do_cord_hole   = is_undef(cord_hole) ? edge_cord_hole_enable : cord_hole;
    hole_inner_d   = is_undef(cord_hole_inner_d) ? edge_cord_hole_inner_d : cord_hole_inner_d;
    hole_pos       = is_undef(cord_hole_pos) ? edge_cord_hole_pos : cord_hole_pos;

    do_cord_under  = is_undef(cord_under) ? edge_cord_under_enable : cord_under;
    under_gap_len  = is_undef(cord_under_gap_len) ? edge_cord_under_gap_len : cord_under_gap_len;

    do_ingress     = is_undef(lid_ingress) ? edge_ingress_enable : lid_ingress;
    in_depth       = is_undef(ingress_depth) ? edge_ingress_depth : ingress_depth;
    in_length      = is_undef(ingress_length) ? edge_ingress_length : ingress_length;
    in_no_rim      = is_undef(ingress_remove_right_rim)
                        ? edge_ingress_remove_right_rim : ingress_remove_right_rim;
    in_z_center    = is_undef(ingress_z_center) ? edge_ingress_z_center : ingress_z_center;

    assert(stem_gripper_sides == 0 || stem_gripper_sides == 1 || stem_gripper_sides == 2,
        "stem_gripper_sides must be 0, 1, or 2");
    assert(hole_pos == "left" || hole_pos == "middle" || hole_pos == "right",
        "cord_hole_pos must be \"left\", \"middle\", or \"right\"");

    union() {
        difference() {
            // Body: either continuous run or ingress U
            if (do_ingress)
                edge_lid_ingress(
                    length, in_depth, in_length, in_no_rim, in_z_center
                );
            else
                linear_extrude(height = length, convexity = 4)
                    polygon(points = edge_profile_points);

            // Cord-under gap: remove lower flange+stem in mid span
            if (do_cord_under)
                edge_cord_under_cut(length, under_gap_len, edge_cord_under_keep_below);
        }

        // Cord hole boss (unioned onto flange/rim); bore cut when enabled
        if (do_cord_hole)
            edge_cord_hole_feature(length, hole_inner_d, hole_pos);

        // Optional end stem-gripper assemblies
        if (stem_gripper_sides >= 1)
            edge_end_stem_gripper_assembly(
                z_pos = -edge_gripper_len + edge_gripper_body_overlap
                    + edge_gripper_body_overlap_z
            );

        if (stem_gripper_sides >= 2)
            edge_end_stem_gripper_assembly(
                z_pos = length - edge_gripper_body_overlap
                    - edge_gripper_body_overlap_z
            );
    }
}
