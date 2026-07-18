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
inner_rim_x_nudge           = 0.5;
inner_rim_width_extra       = 2;

/* [Outer lip] */
outer_lip_gap_height        = 3;
outer_lip_bottom_grip_height = 5;
outer_lip_top_grip_height   = 2;
outer_lip_grip_width        = 3;
outer_lip_grip_len          = 5;
outer_lip_bottom_grip_len   = 15;
outer_lip_sit_extra_scale   = 0.8;

/* [Stem grippers — straddle edgereplica stem] */
gripper_height              = edge_left_flange_h;
gripper_width               = outer_lip_grip_width;
gripper_len                 = outer_lip_bottom_grip_len;
gripper_entry_clearance     = 0.20;
// Each gripper bar is thicker by this amount at the end nearer the corner lip.
gripper_lip_taper           = 0.5;
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
edge_preview_y_nudge        = 2.4;
edge_preview_z_nudge        = 2.4;

// ---------------------------------------------------------------------------
// Fit-alignment planes (from annotated preview)
// ---------------------------------------------------------------------------
inner_rim_origin = ridge_offset_xy - 0.5 * inner_rim_width;

// Green line: bottom of edgereplica body (profile y = 0) after Rx(-90)
// Red line:   top of the corner lip / middle seat ridge (below the tall grippers)
edge_seat_z = cornersquare_rim_height;

// Black line: right-facing profile edge where stem prongs begin
// Blue line:  left-facing face of the inner rim
edge_flush_profile_x = edge_stem_root_left;
edge_flush_world_x   = inner_rim_origin;

// Placement from those planes (Rx(-90): world_z = tz - profile_y, world_x = tx + profile_x)
edge_preview_x = edge_flush_world_x - edge_flush_profile_x;
edge_preview_y = gripper_y_pos + edge_preview_y_nudge;
edge_preview_z = edge_seat_z - edge_preview_z_nudge;

// Stem / grippers follow the seated edge
edge_stem_world_x        = edge_preview_x + edge_tip_center_x;
gripper_along_y_center_x = edge_stem_world_x;
gripper_along_x_center_y = edge_stem_world_x;

// ---------------------------------------------------------------------------
// Derived stem-gripper channel
// ---------------------------------------------------------------------------
gripper_gap_entry = edge_stem_root_w + gripper_entry_clearance;
gripper_gap_seat  = edge_stem_root_w - gripper_friction_interfere;

outer_lip_sit_xy = cornersquare_len + outer_lip_grip_len * outer_lip_sit_extra_scale;
outer_lip_sit_z  = -outer_lip_gap_height + outer_lip_top_grip_height / 2;

// ---------------------------------------------------------------------------
// Modules
// ---------------------------------------------------------------------------

// Y-direction bar: length along +Y. Thicker toward stem at the lip end (y = 0).
// toward_stem_sign: +1 grows in +X (left bar), -1 grows in -X (right bar).
module tapered_stem_gripper_bar(bar_len, bar_width, bar_height, lip_taper, toward_stem_sign = 1) {
    hull() {
        // Near corner lip: thicker by lip_taper toward the stem
        translate([toward_stem_sign < 0 ? -lip_taper : 0, 0, 0])
            cube([bar_width + lip_taper, 0.02, bar_height]);
        // Far from lip: nominal width
        translate([0, bar_len - 0.02, 0])
            cube([bar_width, 0.02, bar_height]);
    }
}

// X-direction bar: length along +X. Thicker toward stem at the lip end (x = 0).
module tapered_stem_gripper_bar_x(bar_len, bar_width, bar_height, lip_taper, toward_stem_sign = 1) {
    hull() {
        // Near corner lip: thicker by lip_taper toward the stem
        translate([0, toward_stem_sign < 0 ? -lip_taper : 0, 0])
            cube([0.02, bar_width + lip_taper, bar_height]);
        // Far from lip: nominal width
        translate([bar_len - 0.02, 0, 0])
            cube([0.02, bar_width, bar_height]);
    }
}

module stem_gripper_pair(
    center_axis,
    along_pos,
    z_pos,
    along_y = true
) {
    // Gap at lip end is tighter by lip_taper on each side
    neg_inner_lip = center_axis - gripper_gap_entry / 2 + gripper_lip_taper;
    pos_inner_lip = center_axis + gripper_gap_entry / 2 - gripper_lip_taper;
    // Far-end outer references use nominal gap (bars shrink away from stem)
    neg_outer_far = center_axis - gripper_gap_entry / 2 - gripper_width;
    pos_inner_far = center_axis + gripper_gap_entry / 2;

    translate([0, 0, z_pos])
    if (along_y) {
        // Left bar — thicker toward stem near corner lip (lower Y)
        translate([neg_outer_far, along_pos, 0])
            tapered_stem_gripper_bar(
                gripper_len, gripper_width, gripper_height,
                gripper_lip_taper, toward_stem_sign = 1
            );
        // Right bar — thicker toward stem near corner lip (lower Y)
        translate([pos_inner_far, along_pos, 0])
            tapered_stem_gripper_bar(
                gripper_len, gripper_width, gripper_height,
                gripper_lip_taper, toward_stem_sign = -1
            );
    } else {
        // -Y bar — thicker toward stem near corner lip (lower X / along_pos end)
        translate([along_pos, neg_outer_far, 0])
            tapered_stem_gripper_bar_x(
                gripper_len, gripper_width, gripper_height,
                gripper_lip_taper, toward_stem_sign = 1
            );
        // +Y bar
        translate([along_pos, pos_inner_far, 0])
            tapered_stem_gripper_bar_x(
                gripper_len, gripper_width, gripper_height,
                gripper_lip_taper, toward_stem_sign = -1
            );
    }
}

module corner_lip_cube() {
    cube([cornersquare_len, cornersquare_len, cornersquare_rim_height]);
}

module corner_inner_rim() {
    translate([
        inner_rim_origin - inner_rim_x_nudge,
        inner_rim_origin,
        cornersquare_rim_height
    ])
    union() {
        cube([
            inner_rim_width + inner_rim_width_extra,
            inner_rim_length,
            cornersquare_ridge_height
        ]);
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

// One edgereplica per corner half (mirror places the other arm).
// Shape/orientation from the closest prior preview: Rx(-90), stem in +Z.
module edge_fit_preview() {
    color(edge_preview_color, edge_preview_alpha)
    translate([edge_preview_x, edge_preview_y, edge_preview_z])
    rotate([-90, 0, 0])
        edgereplica(length = edge_preview_length);
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
