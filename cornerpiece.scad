// Corner half that grips the edgereplica stem with a friction-fit taper.
// Units: millimeters
//
// Edge profile geometry lives in edgereplica.scad so it can be adjusted alone.
include <edgereplica.scad>

/* [Corner square] */
cornersquare_len            = 15;
cornersquare_rim_height     = 2.7;
cornersquare_ridge_height   = 5;
cornersquare_ridge_length   = 8.1;

/* [Ridge / rim layout] */
inner_ridge_thickness       = 3.5;
outer_ridge_depth           = 8.5;
ridge_offset_xy             = 6.5;
inner_rim_width             = 3;
inner_rim_length            = 10;

/* [Outer lip] */
outer_lip_gap_height        = 3;
outer_lip_bottom_grip_height = 5;
outer_lip_top_grip_height   = 2;
outer_lip_grip_width        = 3;
outer_lip_grip_len          = 5;
outer_lip_bottom_grip_len   = 15;
outer_lip_sit_extra_scale   = 0.8; // sit-on-ridge cube grows by grip_len * scale

/* [Stem grippers — straddle edgereplica stem] */
// Height matches left flange on the edge profile.
gripper_height              = edge_left_flange_h;
gripper_width               = outer_lip_grip_width;
gripper_len                 = outer_lip_bottom_grip_len;
// Channel sized to stem root; slight taper for friction fit when sliding on.
gripper_entry_clearance     = 0.20;  // extra gap at rim (slide-on entry)
gripper_friction_interfere  = 0.12;  // tighter gap at grip top (press fit)
gripper_along_y_center_x    = ridge_offset_xy;
gripper_along_x_center_y    = ridge_offset_xy;
gripper_y_pos               = cornersquare_len - 0.5 * outer_lip_grip_len;
gripper_x_pos               = cornersquare_len - 0.5 * outer_lip_grip_len;

/* [Glass / frame] */
glass_thickness             = 5; // confirm

/* [Diagonal split] */
split_angle                 = 45;
split_cut_size              = 100;
split_cut_z                 = -50;

/* [Peg join between halves] */
peg_hole_size               = 2.25;
peg_hole_depth              = 5.2;
peg_hole_y                  = -0.11;
peg_hole_z                  = -0.50;
peg_hole_x1                 = 8;
peg_hole_x2                 = 12;
peg_size                    = 2;
peg_depth                   = 5;
peg_y                       = -5;
peg_z                       = -0.5;
join_rotate_z               = 45;

/* [Assembly / fit preview] */
assembly_spacing_x          = 25;
mirror_axis                 = [-1, 1, 0];
show_edge_fit_preview       = true;
edge_preview_length         = cornersquare_len + outer_lip_bottom_grip_len;
edge_preview_color          = "SteelBlue";
edge_preview_alpha          = 0.45;
// Stem drops in +Z into the gripper channel from the underside of the top bar.
edge_preview_stem_drop      = edge_left_flat_t;

// ---------------------------------------------------------------------------
// Derived stem-gripper channel
// ---------------------------------------------------------------------------
gripper_gap_entry = edge_stem_root_w + gripper_entry_clearance;
gripper_gap_seat  = edge_stem_root_w - gripper_friction_interfere;
gripper_taper_in  = (gripper_gap_entry - gripper_gap_seat) / 2;

outer_lip_sit_xy = cornersquare_len + outer_lip_grip_len * outer_lip_sit_extra_scale;
outer_lip_sit_z  = -outer_lip_gap_height + outer_lip_top_grip_height / 2;
inner_rim_origin = ridge_offset_xy - 0.5 * inner_rim_width;

// ---------------------------------------------------------------------------
// Modules
// ---------------------------------------------------------------------------

// Single gripper bar; inner face leans into the stem channel over height.
// toward_stem_sign: +1 if stem is in +axis of bar's thickness, -1 if in -axis.
module tapered_stem_gripper_bar(bar_len, bar_width, bar_height, taper_in, toward_stem_sign = 1) {
    hull() {
        cube([bar_width, bar_len, 0.02]);
        translate([toward_stem_sign * taper_in, 0, bar_height - 0.02])
            cube([bar_width, bar_len, 0.02]);
    }
}

// Tapered bar with length along X (for X-direction ridge grippers).
module tapered_stem_gripper_bar_x(bar_len, bar_width, bar_height, taper_in, toward_stem_sign = 1) {
    hull() {
        cube([bar_len, bar_width, 0.02]);
        translate([0, toward_stem_sign * taper_in, bar_height - 0.02])
            cube([bar_len, bar_width, 0.02]);
    }
}

// Pair of tapered bars with stem channel centered on center_axis.
// along_y=true: bars extend in +Y, channel gap is along X.
module stem_gripper_pair(
    center_axis,
    along_pos,
    z_pos,
    along_y = true
) {
    neg_inner_entry = center_axis - gripper_gap_entry / 2;
    pos_inner_entry = center_axis + gripper_gap_entry / 2;

    translate([0, 0, z_pos])
    if (along_y) {
        // -X bar (stem toward +X)
        translate([neg_inner_entry - gripper_width, along_pos, 0])
            tapered_stem_gripper_bar(
                gripper_len, gripper_width, gripper_height,
                gripper_taper_in, toward_stem_sign = 1
            );
        // +X bar (stem toward -X)
        translate([pos_inner_entry, along_pos, 0])
            tapered_stem_gripper_bar(
                gripper_len, gripper_width, gripper_height,
                gripper_taper_in, toward_stem_sign = -1
            );
    } else {
        // -Y bar (stem toward +Y)
        translate([along_pos, neg_inner_entry - gripper_width, 0])
            tapered_stem_gripper_bar_x(
                gripper_len, gripper_width, gripper_height,
                gripper_taper_in, toward_stem_sign = 1
            );
        // +Y bar (stem toward -Y)
        translate([along_pos, pos_inner_entry, 0])
            tapered_stem_gripper_bar_x(
                gripper_len, gripper_width, gripper_height,
                gripper_taper_in, toward_stem_sign = -1
            );
    }
}

module corner_lip_cube() {
    cube([cornersquare_len, cornersquare_len, cornersquare_rim_height]);
}

module corner_inner_rim() {
    translate([inner_rim_origin, inner_rim_origin, cornersquare_rim_height])
    union() {
        cube([inner_rim_width, inner_rim_length, cornersquare_ridge_height]);
        cube([inner_rim_length, inner_rim_width, cornersquare_ridge_height]);
    }
}

module corner_sit_on_ridge() {
    translate([0, 0, outer_lip_sit_z])
        cube([outer_lip_sit_xy, outer_lip_sit_xy, outer_lip_top_grip_height]);

    translate([gripper_x_pos, 0, outer_lip_sit_z])
        cube([ridge_offset_xy, outer_lip_sit_xy, outer_lip_top_grip_height]);
}

module cornerhalf_solid() {
    union() {
        corner_lip_cube();
        corner_inner_rim();
        corner_sit_on_ridge();

        // Ridge grippers: slide onto either side of edgereplica stem
        stem_gripper_pair(
            center_axis = gripper_along_y_center_x,
            along_pos   = gripper_y_pos,
            z_pos       = cornersquare_rim_height,
            along_y     = true
        );
        stem_gripper_pair(
            center_axis = gripper_along_x_center_y,
            along_pos   = gripper_x_pos,
            z_pos       = cornersquare_rim_height,
            along_y     = false
        );
    }
}

module cornerhalf() {
    difference() {
        cornerhalf_solid();
        rotate([0, 0, -split_angle])
            translate([0, 0, split_cut_z])
                cube([split_cut_size, split_cut_size, split_cut_size]);
    }
}

module peg_holes() {
    rotate([0, 0, join_rotate_z])
    union() {
        translate([peg_hole_x1, peg_hole_y, peg_hole_z])
            cube([peg_hole_size, peg_hole_depth, peg_hole_size]);
        translate([peg_hole_x2, peg_hole_y, peg_hole_z])
            cube([peg_hole_size, peg_hole_depth, peg_hole_size]);
    }
}

module pegs() {
    rotate([0, 0, join_rotate_z])
    union() {
        translate([peg_hole_x1, peg_y, peg_z])
            cube([peg_size, peg_depth, peg_size]);
        translate([peg_hole_x2, peg_y, peg_z])
            cube([peg_size, peg_depth, peg_size]);
    }
}

module cornerhalf_with_holes() {
    difference() {
        cornerhalf();
        peg_holes();
    }
}

module cornerhalf_with_pegs() {
    union() {
        cornerhalf();
        pegs();
    }
}

// Orient edgereplica so its stem drops into the Y-direction gripper channel.
// Profile: +X along top bar, -Y along stem → after Rx(-90), stem is +Z.
// Extrusion runs along world +Y through the gripper length.
module edgereplica_in_y_gripper_channel() {
    stem_center_x = edge_tip_center_x;
    translate([
        gripper_along_y_center_x - stem_center_x,
        gripper_y_pos,
        cornersquare_rim_height + edge_preview_stem_drop
    ])
    rotate([-90, 0, 0])
        edgereplica(length = edge_preview_length);
}

// Same for the X-direction gripper channel (extrusion along world +X).
module edgereplica_in_x_gripper_channel() {
    stem_center_x = edge_tip_center_x;
    translate([
        gripper_x_pos,
        gripper_along_x_center_y + stem_center_x,
        cornersquare_rim_height + edge_preview_stem_drop
    ])
    rotate([-90, 0, -90])
        edgereplica(length = edge_preview_length);
}

module edge_fit_preview() {
    color(edge_preview_color, edge_preview_alpha) {
        edgereplica_in_y_gripper_channel();
        edgereplica_in_x_gripper_channel();
    }
}

// ---------------------------------------------------------------------------
// Assembly
// ---------------------------------------------------------------------------

cornerhalf_with_holes();
if (show_edge_fit_preview)
    edge_fit_preview();

translate([assembly_spacing_x, 0, 0])
mirror(mirror_axis) {
    cornerhalf_with_pegs();
    if (show_edge_fit_preview)
        edge_fit_preview();
}
