// Rim piece assembly — single source for edge profile + corner geometry
// Units: millimeters
//
// Aquarium lid modular rim: right rim sits on glass; left flange + stem
// take spline for mesh screen. Optional cord pass-throughs, lid ingress
// bays, end joins (male/female), and optional 45° mitered corner arms.
//
// ============================================================================
// QUICK REFERENCE — rim_piece_assembly(...)
// ============================================================================
// length                     rim extrusion length along +Z (mm)
//
// edge_join_ends             0|1|2|3|4   end join placement (default 0)
//   0 = none
//   1 = start male, finish female
//   2 = both ends male
//   3 = finish male, start female
//   4 = both ends female
//   Male and female are mutually exclusive per end (never both on one end).
//   Male unions protruding bars onto the rim; female differences enlarged
//   pockets out of the main rim body (no separate socket cube).
//   If that end also has a corner (cornerpiecenum), the join sits on the
//   mitered arm tip (not on the straight Z end).
//
// cornerpiecenum             0|1|2|3   45° mitered corner arms (default 0)
//   1 = start, 2 = both, 3 = finish
//   Corners are the same edge profile, joined with 45° miters (not a
//   separate corner_solid). Arm length = corner_arm_len.
//   The −X arm is rolled so the left flange sits at lower Z and channels
//   continue across the miter.
//
// cord_hole / cord_hole_inner_d / cord_hole_pos
//   Circle cord boss on flange. pos = "left"|"middle"|"right"
//   Must clear end joins/corners; must not sit in ingress bay opening
//   (middle + ingress → boss on back wall).
//
// cord_under / cord_under_gap_len
//   Mid gap: keep top, shorten flange+stem.
//
// lid_ingress / ingress_depth / ingress_length / ingress_remove_right_rim
//   U bay for spline + pass-through. Bay must fit within length.
//   ingress_length: 0 = off; otherwise >= edge_ingress_length_min so the
//   two bay miters do not interact.
//   Arms/back share 45° miters with a fuse overlap (edge_ingress_joint).
//   glass_sit (default true): on start/finish arms, open the glass-sit
//   channel (world X = glass band) from hook tips up to the top-ridge
//   underside so the Z-run channel continues through the arms. When
//   remove_right_rim, Z also gets a second 45° miter at each arm’s outer Z.
//
// ALSO: rim_corner_assembly(length_a, length_b, ...)
//   One fused L: length_a along +Z, length_b along -X, joined by a 45° miter.
//   Free ends use join_a / join_b: 0=none, 1=male, 2=female.
//   cord_hole_on / ingress_on / cord_under_on: "a" | "b" — which segment
//   gets that feature (default "a").
// ============================================================================

/* [Glass / frame] */
glass_thickness             = 11; // confirm

// Glass grip
depth_below_glass           = 10;

/* [Edge profile dimensions] */
edge_top_width_no_glass     = 10.8;
edge_top_thickness          = 6;
edge_top_width              = edge_top_width_no_glass + glass_thickness;
edge_overall_height         = depth_below_glass + edge_top_thickness;

edge_left_flange_h          = 11.0;
edge_left_flat_w            = 3.4;   // flange inner top → stem root left
edge_stem_root_w            = edge_top_thickness;
edge_stem_tip_w             = edge_top_thickness;
edge_left_flange_t          = 2.8;
edge_left_flange_tip_t      = 1.16;
edge_left_flange_tip_right  = 2;   // bends toward stem
edge_right_segment_tip_t    = 1.16;
edge_left_flat_t            = edge_top_thickness;
edge_right_segment_root_t   = edge_left_flat_t;
edge_default_length         = 50;

/* [End joins — male peg / female socket (consolidated)] */
edge_join_ends              = 0;      // 0|1|2|3|4 — see header
edge_gripper_width          = 3.0;
edge_gripper_height         = depth_below_glass - edge_top_thickness / 2;
edge_gripper_len            = 8.0;
edge_gripper_entry_clearance = 0.20;
edge_gripper_lip_taper      = 0.0;
edge_join_fit_clearance     = 0.5;   // female pockets larger than male (strong press fit)

/* [Top-ridge seat on ends that have joins] */
edge_top_ridge_grip_h       = 5.0;
edge_top_ridge_slot_w       = 3.0;
edge_top_ridge_grip_inset_x = 0.0;
top_ridge_inner_y           = 1.5;
edge_gripper_body_overlap   = 0.05;
edge_gripper_body_overlap_z = 2;

/* [1) Circle cord hole — flange-side boss continuous with rim] */
edge_cord_hole_enable       = false;
edge_cord_hole_inner_d      = 6.0;
edge_cord_hole_pos          = "middle"; // "left" | "middle" | "right"

/* [2) Cord under — mid gap: keep top, shorten flange+stem] */
edge_cord_under_enable      = false;
edge_cord_under_gap_len     = 20.0;
edge_cord_under_keep_below  = 5.0;

/* [3) Lid ingress — U bay of flange+stem edges for spline + pass-through] */
edge_ingress_enable         = false;
edge_ingress_depth          = 30.0;
edge_ingress_length         = 40.0;  // 0 = off; see edge_ingress_length_min when on
edge_ingress_remove_right_rim = false;
edge_ingress_glass_sit      = true;  // strip right rim on arms in glass-sit band
edge_ingress_z_center       = undef;

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
    [edge_stem_root_right + glass_thickness, -edge_right_segment_root_t],
    [edge_stem_root_right + glass_thickness, -edge_right_segment_root_t - depth_below_glass],
    [edge_stem_root_right + glass_thickness + edge_right_segment_root_t,
        -edge_right_segment_root_t - depth_below_glass],
    [edge_stem_root_right + edge_right_segment_root_t + glass_thickness, 0],
];

// Full profile width in X (glass hook included) — used to map the corner arm.
edge_profile_max_x = edge_stem_root_right + edge_right_segment_root_t + glass_thickness;
// Minimum ingress bay length so the two 45° end miters do not collide (0 = off).
edge_ingress_length_min = 2;

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

function edge_cord_hole_z(length, pos, do_ingress = false, bay_len = 0, z_center = undef) =
    let (
        zc = is_undef(z_center) ? length / 2 : z_center,
        z0 = zc - bay_len / 2,
        z1 = zc + bay_len / 2
    )
    !do_ingress ? (
        pos == "left"  ? length / 3 :
        pos == "right" ? 2 * length / 3 :
                         length / 2
    ) : (
        pos == "left"  ? z0 / 2 :
        pos == "right" ? (z1 + length) / 2 :
                         zc
    );

function edge_select_profile(remove_right_rim) =
    remove_right_rim ? edge_profile_points_no_right_rim : edge_profile_points;

// Resolve join sex at one end: "none" | "male" | "female"
// ends: 0 none | 1 start♂ finish♀ | 2 both♂ | 3 start♀ finish♂ | 4 both♀
function edge_join_start_kind(ends) =
    ends == 0 ? "none" :
    ends == 1 ? "male" :
    ends == 2 ? "male" :
    ends == 3 ? "female" :
    ends == 4 ? "female" : "none";

function edge_join_finish_kind(ends) =
    ends == 0 ? "none" :
    ends == 1 ? "female" :
    ends == 2 ? "male" :
    ends == 3 ? "male" :
    ends == 4 ? "female" : "none";

// Mitered corners extend off-axis; along +Z they only need join clearance.
function rim_end_clearance_start(join_ends, cornerpiecenum) =
    let (
        kind = edge_join_start_kind(join_ends),
        grip = kind == "none" ? 0 : edge_gripper_len
    )
    grip;

function rim_end_clearance_finish(join_ends, cornerpiecenum) =
    let (
        kind = edge_join_finish_kind(join_ends),
        grip = kind == "none" ? 0 : edge_gripper_len
    )
    grip;

function edge_cord_hole_outer_radius(inner_d) =
    (inner_d + inner_d / 3) / 2;

// ---------------------------------------------------------------------------
// Corner / assembly parameters
// ---------------------------------------------------------------------------

/* [Corner square — legacy print helpers / arm length] */
cornersquare_len            = 15;
corner_arm_len              = cornersquare_len; // perpendicular mitered arm
corner_miter_joint          = 0.35;             // fuse pull across 45° plane
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
outer_lip_gap_height         = 3;
outer_lip_bottom_grip_height = 5;
outer_lip_top_grip_height    = 2;
outer_lip_grip_width         = 3;
outer_lip_grip_len           = 5;
outer_lip_bottom_grip_len    = 15;
outer_lip_sit_extra_scale    = 0.8;

/* [Stem grippers — corner arms] */
gripper_height              = edge_left_flange_h;
gripper_width               = outer_lip_grip_width;
gripper_len                 = outer_lip_bottom_grip_len;
gripper_entry_clearance     = 0.20;
gripper_lip_taper           = 0.5;
gripper_y_pos               = cornersquare_len - 0.5 * outer_lip_grip_len;
gripper_x_pos               = cornersquare_len - 0.5 * outer_lip_grip_len;

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

inner_rim_origin = ridge_offset_xy - 0.5 * inner_rim_width;
edge_seat_z = cornersquare_rim_height;
edge_flush_profile_x = edge_stem_root_left;
edge_flush_world_x   = inner_rim_origin;
edge_preview_x = edge_flush_world_x - edge_flush_profile_x;
edge_preview_y = gripper_y_pos + edge_preview_y_nudge;
edge_preview_z = edge_seat_z - edge_preview_z_nudge;
edge_stem_world_x        = edge_preview_x + edge_tip_center_x;
gripper_along_y_center_x = edge_stem_world_x;
gripper_along_x_center_y = edge_stem_world_x;

gripper_gap_entry = edge_stem_root_w + gripper_entry_clearance;
outer_lip_sit_xy = cornersquare_len + outer_lip_grip_len * outer_lip_sit_extra_scale;
outer_lip_sit_z  = -outer_lip_gap_height + outer_lip_top_grip_height / 2;

// ---------------------------------------------------------------------------
// Consolidated end-join modules (male peg / female socket)
// ---------------------------------------------------------------------------

module edge_tapered_stem_gripper_bar(bar_len, bar_width, bar_height, lip_taper, toward_stem_sign = 0, grow = 0) {
    h = bar_height + edge_gripper_body_overlap + grow;
    w = edge_top_thickness / 2 + grow;
    hull() {
        translate([toward_stem_sign < 0 ? -lip_taper - grow / 2 : -grow / 2, -bar_height - grow, 0])
            cube([w + lip_taper, h, 0.02]);
        translate([-grow / 2, -bar_height - grow, bar_len - 0.02])
            cube([w, h, 0.02]);
    }
}

module edge_join_male_bars(z_pos = 0, grow = 0) {
    translate([0, -edge_top_thickness, z_pos]) {
        translate([edge_top_width_no_glass - edge_gripper_width - grow / 2, 0, 0])
            edge_tapered_stem_gripper_bar(
                edge_gripper_len + grow, edge_gripper_width, edge_gripper_height,
                edge_gripper_lip_taper, toward_stem_sign = 1, grow = grow
            );
        translate([edge_stem_root_right + glass_thickness + edge_top_thickness / 4 - grow / 2, 0, 0])
            edge_tapered_stem_gripper_bar(
                edge_gripper_len + grow, edge_gripper_width, edge_gripper_height,
                edge_gripper_lip_taper, toward_stem_sign = -1, grow = grow
            );
    }
}

module edge_join_male_ridge(z_pos = 0, grow = 0) {
    cube_w = edge_top_thickness / 2 + grow;
    if (cube_w > 0)
        translate([
            edge_stem_root_right-edge_top_thickness/2-grow/2,
            -edge_top_thickness / 2 - cube_w / 2-grow/2,
            z_pos-grow/2
        ])
            cube([
                glass_thickness + edge_top_thickness + grow,
                cube_w+grow,
                edge_gripper_len + grow
            ]);
}

// Male = protruding join bars + ridge seat (current edge gripper).
module edge_join_male(z_pos = 0) {
    edge_join_male_bars(z_pos = z_pos, grow = 0);
    edge_join_male_ridge(z_pos = z_pos, grow = 0);
}

// Female = cutter only (enlarged male). Caller must difference() this from the rim body.
// No separate socket cube — pockets are cut out of the main rim assembly.
module edge_join_female_cutter(z_pos = 0) {
    c = edge_join_fit_clearance;
    edge_join_male_bars(z_pos = z_pos, grow = c);
    edge_join_male_ridge(z_pos = z_pos, grow = c);
}

// Place male solid or female cutter at z_pos.
// turn90: when rim ends at a corner, rotate join 90° onto the perpendicular arm.
module edge_end_join(z_pos = 0, kind = "male", turn90 = false) {
    if (kind == "male" || kind == "female") {
        if (turn90) {
            translate([0, 0, z_pos + edge_gripper_len / 2])
            rotate([0, -90, 0])
            translate([0, 0, -edge_gripper_len / 2]) {
                if (kind == "male")
                    edge_join_male(z_pos = 0);
                else
                    edge_join_female_cutter(z_pos = 0);
            }
        } else {
            if (kind == "male")
                edge_join_male(z_pos = z_pos);
            else
                edge_join_female_cutter(z_pos = z_pos);
        }
    }
}

// Z placement: males protrude past the end; females cut into the rim interior.
function edge_join_z_start(kind) =
    kind == "female"
        ? 0
        : (-edge_gripper_len + edge_gripper_body_overlap + edge_gripper_body_overlap_z);

function edge_join_z_finish(kind, length) =
    kind == "female"
        ? (length - edge_gripper_len)
        : (length - edge_gripper_body_overlap - edge_gripper_body_overlap_z);

// Back-compat aliases
module edge_join_female(z_pos = 0) { edge_join_female_cutter(z_pos = z_pos); }
module edge_stem_gripper_pair(z_pos = 0) { edge_join_male_bars(z_pos = z_pos); }
module edge_top_ridge_grip_cube(z_pos = 0) { edge_join_male_ridge(z_pos = z_pos); }
module edge_end_stem_gripper_assembly(z_pos = -2) { edge_join_male(z_pos = z_pos); }

// ---------------------------------------------------------------------------
// Cord hole / cord under / ingress
// ---------------------------------------------------------------------------

module edge_cord_hole_feature(length, inner_d, pos,
    do_ingress = false, ingress_depth = 0, bay_len = 0, z_center = undef
) {
    zc = edge_cord_hole_z(length, pos, do_ingress, bay_len, z_center);
    edge_cord_hole_outer_d = inner_d / 3;
    outer_r = (inner_d + edge_cord_hole_outer_d) / 2;
    // Flange tip is x=0 on the main, x=−depth on the ingress back wall.
    flange_tip_x = (do_ingress && pos == "middle") ? -ingress_depth : 0;
    // Nest into the flange (+X) so the ring intersects for a strong joint.
    fuse = 2;
    x0 = flange_tip_x + fuse - outer_r;

    difference() {
        translate([x0, -edge_left_flange_h, zc])
        rotate([-90, 0, 0])
        difference() {
            cylinder(d = inner_d + edge_cord_hole_outer_d, h = edge_left_flange_h, $fn = 48);
            translate([0, 0, -0.01])
                cylinder(d = inner_d, h = edge_left_flange_h + 0.02, $fn = 48);
        }
        // Remove boss that would sit inside the flange past the fuse band.
        translate([
            flange_tip_x + fuse,
            -edge_left_flange_h - 0.4,
            zc - outer_r - 0.2
        ])
            cube([
                edge_profile_max_x + outer_r + 1,
                edge_left_flange_h + 0.8,
                2 * outer_r + 0.4
            ]);
    }
}

module edge_cord_under_cut(length, gap_len, keep_below) {
    z0 = (length - gap_len) / 2;
    cut_top_y = -(edge_top_thickness + keep_below);
    cut_h = edge_overall_height + cut_top_y + 0.02;
    if (cut_h > 0 && gap_len > 0)
        translate([-0.01, -edge_overall_height - 0.01, z0])
            cube([edge_stem_root_right + 0.02, cut_h, gap_len]);
}

/* [Lid ingress joints] */
// Fuse overlap across each 45° miter so main/arms/back share volume (touch).
edge_ingress_joint = 0.35;

// Profile-X / world-X landmarks on the +Z run:
//   inner right rim inner — start of the glass channel (black)
//   glass channel spans [inner, inner + glass_thickness]
edge_inner_right_rim_inner_x = edge_stem_root_right;
edge_glass_sit_x0            = edge_inner_right_rim_inner_x;
edge_glass_sit_x1            = edge_inner_right_rim_inner_x + glass_thickness;
// Underside of the top deck / top ridge (glass sits under this).
edge_top_ridge_bottom_y      = -edge_right_segment_root_t;
// Lowest tip of the glass-hook lip.
edge_glass_hook_tip_y        = -edge_right_segment_root_t - depth_below_glass;

// Full profile width so ingress outer rim meets the Z-piece at the same X.
function edge_ingress_profile_w(remove_right_rim) =
    remove_right_rim ? edge_stem_root_right : edge_profile_max_x;

function edge_miter_span(depth, bay_len) =
    2 * (depth + bay_len + edge_top_width + edge_overall_height);

module edge_profile_extrude(seg_len, remove_right_rim = false) {
    linear_extrude(height = seg_len, convexity = 4)
        polygon(points = edge_select_profile(remove_right_rim));
}

// Half-space cutter for a 45° miter in the XZ plane.
// Complementary flip at the same (cx,cz,rot_y) yields a fuse band of ~2*pull.
module edge_miter_slab(cx, cz, rot_y, flip = false, pull = edge_ingress_joint, span = 0) {
    big = (span > 0 ? span : edge_miter_span(edge_ingress_depth, edge_ingress_length))
        + edge_default_length;
    z_off = (flip ? -big : 0) + (flip ? -pull : pull);
    translate([cx, -edge_overall_height - abs(pull) - 1, cz])
    rotate([0, rot_y, 0])
    translate([-big / 2, 0, z_off])
        cube([big, edge_overall_height + edge_top_ridge_grip_h + edge_top_width + 2, big]);
}

module edge_run_z(z0, seg_len, remove_right_rim = false) {
    if (seg_len > 0.01)
        translate([0, 0, z0])
            edge_profile_extrude(seg_len, remove_right_rim);
}

// Extrude profile along -X. rim_toward_neg_z selects which way the profile
// faces after the bend (must keep z ∈ [z_flange − width, z_flange] so the
// arm overlaps the +Z run — Ry(270) without −seg_len parks the arm past z_flange).
module edge_run_neg_x(z_flange, seg_len, rim_toward_neg_z = true, remove_right_rim = false) {
    if (seg_len > 0.01) {
        if (rim_toward_neg_z) {
            // (px,py,t) → (t − seg_len, py, z_flange − px): x ∈ [−seg_len, 0],
            // z ∈ [z_flange − profile_w, z_flange] overlaps the main run.
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

// Open a continuous glass-sit channel through the perpendicular ingress arms.
// X: only the glass-channel band on those arms (not the bay / opposite side).
// Y: hook tips → underside of the top ridge (top deck stays).
// Z: glass-channel span of the arm profile so the Z-run channel continues.
module edge_ingress_arm_glass_sit_cut(z_flange, depth, rim_toward_neg_z) {
    j   = edge_ingress_joint;
    x0  = edge_glass_sit_x0 - j;
    xs  = (edge_glass_sit_x1 - edge_glass_sit_x0) + 2 * j;
    y0  = edge_glass_hook_tip_y - 0.02;
    ys  = (edge_top_ridge_bottom_y - edge_glass_hook_tip_y) + 0.04;
    rr0 = edge_inner_right_rim_inner_x;
    gw  = glass_thickness;
    if (xs > 0.01 && ys > 0.01) {
        if (rim_toward_neg_z)
            // Far arm: z = z_flange − px → glass channel at lower Z.
            translate([x0, y0, z_flange - rr0 - gw - j])
                cube([xs, ys, gw + 2 * j]);
        else
            // Near arm: z = z_flange + px → glass channel at higher Z.
            translate([x0, y0, z_flange + rr0 - j])
                cube([xs, ys, gw + 2 * j]);
    }
}

// Bay pocket + complementary 45° faces that mate with the arms.
// Miter slabs are clipped to each corner zone so they do not slice the rest
// of the rim. The square middle cut starts only after the full miter span
// (Δz ≈ arm profile width).
// When remove_right_rim: primary miter spans the truncated arm; a second
// miter trims the Z right rim at each arm’s outer Z (green).
module edge_ingress_bay_opening_cut(z0, z1, depth, bay_len, remove_right_rim, zc) {
    W    = edge_profile_max_x;
    mw   = edge_ingress_profile_w(remove_right_rim);
    j    = edge_ingress_joint;
    span = edge_miter_span(depth, bay_len);
    y0   = -edge_overall_height - 1;
    yh   = edge_overall_height + W + 2;
    mz   = mw + 2 * j;

    // Primary 45° inner corners on the Z-piece (same planes as the arms).
    intersection() {
        edge_miter_slab(0, z0, -45, flip = false, pull = j, span = span);
        translate([-j, y0, z0 - j])
            cube([mw + 2 * j, yh, mz]);
    }
    intersection() {
        edge_miter_slab(0, z1, 45, flip = true, pull = j, span = span);
        translate([-j, y0, z1 - mw - j])
            cube([mw + 2 * j, yh, mz]);
    }

    // Between the (truncated) miter tips, remove all X of the main.
    z_mid0 = z0 + mw - j;
    z_mid1 = z1 - mw + j;
    if (z_mid1 > z_mid0)
        translate([-j, y0, z_mid0])
            cube([W + 2 * j, yh, z_mid1 - z_mid0]);

    // Second miters (green): when arms omit the right rim, trim the Z right
    // rim at the arm outer Z so it meets the truncated profile width.
    if (remove_right_rim && W > mw + 0.01) {
        z_near_outer = z0 + mw;
        z_far_outer  = z1 - mw;
        mz2 = (W - mw) + 2 * j;

        intersection() {
            edge_miter_slab(mw, z_near_outer, -45, flip = false, pull = j, span = span);
            translate([mw - j, y0, z_near_outer - j])
                cube([(W - mw) + 2 * j, yh, mz2]);
        }
        intersection() {
            edge_miter_slab(mw, z_far_outer, 45, flip = true, pull = j, span = span);
            translate([mw - j, y0, z_far_outer - (W - mw) - j])
                cube([(W - mw) + 2 * j, yh, mz2]);
        }
    }
}

module edge_ingress_arm_near(z0, depth, bay_len, remove_right_rim, glass_sit = true) {
    mw   = edge_ingress_profile_w(remove_right_rim);
    j    = edge_ingress_joint;
    span = edge_miter_span(depth, bay_len);
    // Full profile when glass_sit will selectively strip the right rim band.
    use_full = glass_sit && !remove_right_rim;
    arm_w = use_full ? edge_profile_max_x : mw;
    difference() {
        translate([arm_w, 0, 0])
            edge_run_neg_x(z0, depth + arm_w + j, false, remove_right_rim && !use_full);
        edge_miter_slab(0, z0, -45, flip = true,  pull = j, span = span);
        edge_miter_slab(-depth, z0, -45, flip = false, pull = j, span = span);
        if (use_full)
            edge_ingress_arm_glass_sit_cut(z0, depth, false);
        if (remove_right_rim && edge_profile_max_x > mw + 0.01)
            edge_miter_slab(mw, z0 + mw, -45, flip = true, pull = j, span = span);
    }
}

module edge_ingress_arm_far(z1, depth, bay_len, remove_right_rim, glass_sit = true) {
    mw   = edge_ingress_profile_w(remove_right_rim);
    j    = edge_ingress_joint;
    span = edge_miter_span(depth, bay_len);
    use_full = glass_sit && !remove_right_rim;
    arm_w = use_full ? edge_profile_max_x : mw;
    difference() {
        translate([arm_w, 0, 0])
            edge_run_neg_x(z1, depth + arm_w + j, true, remove_right_rim && !use_full);
        edge_miter_slab(0, z1, 45, flip = false, pull = j, span = span);
        edge_miter_slab(-depth, z1, 45, flip = true,  pull = j, span = span);
        if (use_full)
            edge_ingress_arm_glass_sit_cut(z1, depth, true);
        if (remove_right_rim && edge_profile_max_x > mw + 0.01)
            edge_miter_slab(mw, z1 - mw, 45, flip = false, pull = j, span = span);
    }
}

module edge_ingress_back(z0, z1, depth, bay_len, remove_right_rim) {
    mw   = edge_ingress_profile_w(remove_right_rim);
    j    = edge_ingress_joint;
    span = edge_miter_span(depth, bay_len);
    difference() {
        translate([-depth, 0, 0])
            edge_run_z(z0 - j, (z1 - z0) + 2 * j, remove_right_rim);
        edge_miter_slab(-depth, z0, -45, flip = true,  pull = j, span = span);
        edge_miter_slab(-depth, z1,  45, flip = false, pull = j, span = span);
    }
}

module edge_lid_ingress(length, depth, bay_len, remove_right_rim = false, z_center,
    clear_start = 0, clear_finish = 0, glass_sit = true
) {
    zc = is_undef(z_center) ? length / 2 : z_center;
    z0 = zc - bay_len / 2;
    z1 = zc + bay_len / 2;
    mw = edge_ingress_profile_w(remove_right_rim);
    // Arms keep full outer width when glass_sit selectively strips the rim.
    arm_ref_w = (glass_sit && !remove_right_rim) ? edge_profile_max_x : mw;
    need_start  = arm_ref_w + clear_start;
    need_finish = arm_ref_w + clear_finish;

    assert(bay_len > 0, "ingress bay length must be > 0");
    assert(bay_len > 2 * arm_ref_w + 1,
        str("ingress bay too short for 45° miters across profile: bay=", bay_len,
            " need > ", 2 * arm_ref_w + 1));
    assert(bay_len <= length,
        str("ingress bay too long for piece + end accessories: bay=", bay_len,
            " need clearances start=", need_start, " finish=", need_finish,
            " within length=", length));

    union() {
        difference() {
            edge_run_z(0, length, false);
            edge_ingress_bay_opening_cut(z0, z1, depth, bay_len, remove_right_rim, zc);
        }
        edge_ingress_arm_near(z0, depth, bay_len, remove_right_rim, glass_sit);
        edge_ingress_arm_far(z1, depth, bay_len, remove_right_rim, glass_sit);
        edge_ingress_back(z0, z1, depth, bay_len, remove_right_rim);
    }
}

// ---------------------------------------------------------------------------
// 45° mitered corner arms (same edge profile — not separate corner_solid)
//
// Finish corner, shared plane z = z_end − W + x  (W = edge_profile_max_x):
//   Main keeps below the plane; arm keeps above. Complementary flip, same rot.
//
// Arm orientation (Ry(−90) shifted by −W in Z):
//   left flange (profile x=0) at z = z_end − W   ← lower Z, meets main flange
//   glass hook (profile x=W)  at z = z_end
//   feature at profile x=px continues on the arm at z = z_end − W + px
//   arm_len = TOTAL arm length; extrude t ∈ [0, arm_len]; tip at world x = W − arm_len
// ---------------------------------------------------------------------------

module rim_corner_miter_clip(z_end, arm_len) {
    W  = edge_profile_max_x;
    j  = corner_miter_joint;
    yh = edge_overall_height + W + 2;
    translate([-arm_len - j, -edge_overall_height - 1, z_end - W - j])
        cube([arm_len + W + 2 * j, yh, W + arm_len + 2 * j]);
}

module rim_corner_finish_miter_cut(z_end, arm_len = corner_arm_len) {
    W    = edge_profile_max_x;
    span = edge_miter_span(arm_len, W);
    intersection() {
        // Same plane as the arm, opposite half-space.
        edge_miter_slab(0, z_end - W, -45, flip = false, pull = corner_miter_joint, span = span);
        rim_corner_miter_clip(z_end, arm_len);
    }
}

module rim_corner_start_miter_cut(arm_len = corner_arm_len) {
    mirror([1, 0, 0])
        mirror([0, 0, 1])
            rim_corner_finish_miter_cut(0, arm_len);
}

// Perpendicular arm at finish (along −X). Flange at lower Z.
// arm_len is the TOTAL segment length (miter band + free run), same meaning as
// length_a — tip at local t = arm_len → world x = W − arm_len (span = arm_len).
module rim_corner_arm_finish(z_end, arm_len = corner_arm_len) {
    j    = corner_miter_joint;
    W    = edge_profile_max_x;
    span = edge_miter_span(arm_len, W);
    difference() {
        // (px,py,t) → (W − t, py, z_end − W + px); t ∈ [0, arm_len]
        translate([W, 0, z_end - W])
        rotate([0, -90, 0])
            edge_profile_extrude(arm_len + j, false);
        edge_miter_slab(0, z_end - W, -45, flip = true, pull = j, span = span);
    }
}

module rim_corner_arm_start(arm_len = corner_arm_len) {
    mirror([1, 0, 0])
        mirror([0, 0, 1])
            rim_corner_arm_finish(0, arm_len);
}

// Joins at the flipped arm tip — same Ry(−90) frame as rim_corner_arm_finish.
// Caller translates to the Z-piece finish (z = length) first.
// arm_len = total B length; tip is at local t = arm_len (not arm_len + W).
module rim_corner_join_finish(arm_len, kind) {
    W = edge_profile_max_x;
    local_tip = arm_len;
    translate([W, 0, -W])
    rotate([0, -90, 0]) {
        if (kind == "male")
            edge_end_join(
                z_pos = edge_join_z_finish("male", local_tip),
                kind = "male"
            );
        else if (kind == "female") {
            zpos = edge_join_z_finish("female", local_tip);
            c = edge_join_fit_clearance;
            edge_join_male_bars(z_pos = zpos, grow = c);
            // End-face ridge pocket (−X tip), same presentation as Z female.
            // Do not start at z_pos−grow/2 — that inward overrun severs the
            // flipped-arm glass hook (Volumes ≥ 3).
            edge_join_female_ridge_arm(z_pos = zpos, grow = c);
        }
    }
}

// Female ridge for the flipped −X arm: opens on the tip end face (not Y),
// matching the Z-piece female end. Same XY footprint as the male ridge.
module edge_join_female_ridge_arm(z_pos = 0, grow = 0) {
    cube_w = edge_top_thickness / 2 + grow;
    if (cube_w > 0)
        translate([
            edge_stem_root_right - edge_top_thickness / 2 - grow / 2,
            -edge_top_thickness / 2 - cube_w / 2 - grow / 2,
            z_pos
        ])
            cube([
                glass_thickness + edge_top_thickness + grow,
                cube_w + grow,
                edge_gripper_len + grow
            ]);
}

module rim_corner_join_start(arm_len, kind) {
    mirror([1, 0, 0])
        mirror([0, 0, 1])
            rim_corner_join_finish(arm_len, kind);
}

// ---------------------------------------------------------------------------
// Corner modules
// ---------------------------------------------------------------------------

module tapered_stem_gripper_bar(bar_len, bar_width, bar_height, lip_taper, toward_stem_sign = 1) {
    hull() {
        translate([toward_stem_sign < 0 ? -lip_taper : 0, 0, 0])
            cube([bar_width + lip_taper, 0.02, bar_height]);
        translate([0, bar_len - 0.02, 0])
            cube([bar_width, 0.02, bar_height]);
    }
}

module tapered_stem_gripper_bar_x(bar_len, bar_width, bar_height, lip_taper, toward_stem_sign = 1) {
    hull() {
        translate([0, toward_stem_sign < 0 ? -lip_taper : 0, 0])
            cube([0.02, bar_width + lip_taper, bar_height]);
        translate([bar_len - 0.02, 0, 0])
            cube([0.02, bar_width, bar_height]);
    }
}

module stem_gripper_pair(center_axis, along_pos, z_pos, along_y = true) {
    neg_outer_far = center_axis - gripper_gap_entry / 2 - gripper_width;
    pos_inner_far = center_axis + gripper_gap_entry / 2;

    translate([0, 0, z_pos])
    if (along_y) {
        translate([neg_outer_far, along_pos, 0])
            tapered_stem_gripper_bar(
                gripper_len, gripper_width, gripper_height,
                gripper_lip_taper, toward_stem_sign = 1
            );
        translate([pos_inner_far, along_pos, 0])
            tapered_stem_gripper_bar(
                gripper_len, gripper_width, gripper_height,
                gripper_lip_taper, toward_stem_sign = -1
            );
    } else {
        translate([along_pos, neg_outer_far, 0])
            tapered_stem_gripper_bar_x(
                gripper_len, gripper_width, gripper_height,
                gripper_lip_taper, toward_stem_sign = 1
            );
        translate([along_pos, pos_inner_far, 0])
            tapered_stem_gripper_bar_x(
                gripper_len, gripper_width, gripper_height,
                gripper_lip_taper, toward_stem_sign = -1
            );
    }
}

module corner_lip_cube() {
    cube([cornersquare_len, cornersquare_len, cornersquare_rim_height + outer_lip_top_grip_height]);
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

// Per-axis stem grippers in corner frame (along_y / along_x).
// Start Ry(270): along_x → rim Z (omit). Finish Ry(-180): along_y → rim Z (omit).
module corner_solid(include_along_y = true, include_along_x = true) {
    union() {
        corner_lip_cube();
        corner_inner_rim();
        corner_sit_on_ridge();

        if (include_along_y)
            stem_gripper_pair(
                center_axis = gripper_along_y_center_x,
                along_pos   = gripper_y_pos,
                z_pos       = cornersquare_rim_height,
                along_y     = true
            );

        if (include_along_x)
            stem_gripper_pair(
                center_axis = gripper_along_x_center_y,
                along_pos   = gripper_x_pos,
                z_pos       = cornersquare_rim_height,
                along_y     = false
            );
    }
}

module cornerhalf(include_along_y = true, include_along_x = true) {
    difference() {
        corner_solid(include_along_y = include_along_y, include_along_x = include_along_x);
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

module cornerhalf_with_holes(include_along_y = true, include_along_x = true) {
    difference() {
        cornerhalf(include_along_y = include_along_y, include_along_x = include_along_x);
        peg_holes();
    }
}

module cornerhalf_with_pegs(include_along_y = true, include_along_x = true) {
    union() {
        cornerhalf(include_along_y = include_along_y, include_along_x = include_along_x);
        pegs();
    }
}

module edge_fit_preview() {
    color(edge_preview_color, edge_preview_alpha)
    translate([edge_preview_x, edge_preview_y, edge_preview_z])
    rotate([-90, 0, 0])
        rim_piece_assembly(length = edge_preview_length);
}

module corner_print_pair(include_stem_grippers = true) {
    translate([-assembly_spacing_x, 0, 0])
        cornerhalf_with_holes(
            include_along_y = include_stem_grippers,
            include_along_x = include_stem_grippers
        );
    translate([assembly_spacing_x, 0, 0])
    mirror(mirror_axis)
        cornerhalf_with_pegs(
            include_along_y = include_stem_grippers,
            include_along_x = include_stem_grippers
        );
    if (show_edge_fit_preview)
        edge_fit_preview();
}

// ---------------------------------------------------------------------------
// Main: straight rim piece
// ---------------------------------------------------------------------------

module rim_piece_assembly(
    length = edge_default_length,
    // End joins (replaces stem_gripper_sides; alias kept below)
    edge_join_ends = undef,
    stem_gripper_sides = undef, // deprecated alias → edge_join_ends
    // Cord hole
    cord_hole = undef,
    cord_hole_inner_d = undef,
    cord_hole_pos = undef,
    // Cord under
    cord_under = undef,
    cord_under_gap_len = undef,
    // Lid ingress
    lid_ingress = undef,
    ingress_depth = undef,
    ingress_length = undef,
    ingress_remove_right_rim = undef,
    glass_sit = undef,
    ingress_z_center = undef,
    cornerpiecenum = 0,
    // Miter-only ends (no arm) — used by rim_corner_assembly so two segments meet at 45°.
    corner_miter_start = false,
    corner_miter_finish = false,
    corner_arm_length = undef
) {
    join_ends = !is_undef(edge_join_ends) ? edge_join_ends
        : (!is_undef(stem_gripper_sides) ? stem_gripper_sides : 0);

    do_cord_hole   = is_undef(cord_hole) ? edge_cord_hole_enable : cord_hole;
    hole_inner_d   = is_undef(cord_hole_inner_d) ? edge_cord_hole_inner_d : cord_hole_inner_d;
    hole_pos       = is_undef(cord_hole_pos) ? edge_cord_hole_pos : cord_hole_pos;

    do_cord_under  = is_undef(cord_under) ? edge_cord_under_enable : cord_under;
    under_gap_len  = is_undef(cord_under_gap_len) ? edge_cord_under_gap_len : cord_under_gap_len;

    do_ingress     = (is_undef(lid_ingress) ? edge_ingress_enable : lid_ingress)
                        && ((is_undef(ingress_length) ? edge_ingress_length : ingress_length) > 0);
    in_depth       = is_undef(ingress_depth) ? edge_ingress_depth : ingress_depth;
    in_length_raw  = is_undef(ingress_length) ? edge_ingress_length : ingress_length;
    // Pad bay by full profile width so outer-rim miters fit (same X as Z-piece).
    in_length      = in_length_raw + 2 * edge_profile_max_x;
    in_no_rim      = is_undef(ingress_remove_right_rim)
                        ? edge_ingress_remove_right_rim : ingress_remove_right_rim;
    do_glass_sit   = is_undef(glass_sit) ? edge_ingress_glass_sit : glass_sit;
    in_z_center    = is_undef(ingress_z_center) ? edge_ingress_z_center : ingress_z_center;

    kind_start  = edge_join_start_kind(join_ends);
    kind_finish = edge_join_finish_kind(join_ends);
    corner_start  = (cornerpiecenum == 1 || cornerpiecenum == 2);
    corner_finish = (cornerpiecenum == 2 || cornerpiecenum == 3);
    arm_len = is_undef(corner_arm_length) ? corner_arm_len : corner_arm_length;
    miter_start  = corner_start  || corner_miter_start;
    miter_finish = corner_finish || corner_miter_finish;

    clear_start  = rim_end_clearance_start(join_ends, cornerpiecenum)
        + ((miter_start && !corner_start) ? edge_profile_max_x : 0);
    clear_finish = rim_end_clearance_finish(join_ends, cornerpiecenum)
        + ((miter_finish && !corner_finish) ? edge_profile_max_x : 0);

    zc_eff = is_undef(in_z_center) ? length / 2 : in_z_center;
    z0_bay = zc_eff - in_length / 2;
    z1_bay = zc_eff + in_length / 2;
    hole_z = edge_cord_hole_z(length, hole_pos, do_ingress, in_length, in_z_center);
    hole_r = edge_cord_hole_outer_radius(hole_inner_d);

    assert(join_ends >= 0 && join_ends <= 4, "edge_join_ends must be 0..4");
    assert(cornerpiecenum == 0 || cornerpiecenum == 1
            || cornerpiecenum == 2 || cornerpiecenum == 3,
        "cornerpiecenum must be 0, 1, 2, or 3");
    assert(hole_pos == "left" || hole_pos == "middle" || hole_pos == "right",
        "cord_hole_pos must be \"left\", \"middle\", or \"right\"");
    if (do_ingress) {
        assert(in_length_raw >= edge_ingress_length_min,
            str("ingress_length must be 0 (off) or >= ", edge_ingress_length_min,
                " so bay miters do not interact (got ", in_length_raw, ")"));
    }

    if (do_cord_hole) {
        assert(hole_z - hole_r >= clear_start && hole_z + hole_r <= length - clear_finish,
            str("cord hole overlaps end corner/join zone at z=", hole_z));
        if (do_ingress && hole_pos != "middle") {
            assert(hole_z + hole_r <= z0_bay || hole_z - hole_r >= z1_bay,
                str("cord hole must not pass through ingress bay (z=", hole_z,
                    " bay=[", z0_bay, ",", z1_bay, "])"));
        }
    }

    if (do_cord_under) {
        assert(under_gap_len < length - clear_start - clear_finish,
            "cord_under gap must fit between end accessories");
    }

    difference() {
        union() {
            difference() {
                if (do_ingress)
                    edge_lid_ingress(
                        length, in_depth, in_length, in_no_rim, in_z_center,
                        clear_start = clear_start, clear_finish = clear_finish,
                        glass_sit = do_glass_sit
                    );
                else
                    linear_extrude(height = length, convexity = 4)
                        polygon(points = edge_profile_points);

                if (do_cord_under)
                    edge_cord_under_cut(length, under_gap_len, edge_cord_under_keep_below);

                // 45° end miters (standalone arm and/or mating segment)
                if (miter_start)
                    rim_corner_start_miter_cut(arm_len);
                if (miter_finish)
                    rim_corner_finish_miter_cut(length, arm_len);
            }

            if (do_cord_hole)
                edge_cord_hole_feature(
                    length, hole_inner_d, hole_pos,
                    do_ingress, in_depth, in_length, in_z_center
                );

            // Integrated 45° mitered corner arms (same profile as the rim)
            if (corner_start)
                rim_corner_arm_start(arm_len);
            if (corner_finish)
                rim_corner_arm_finish(length, arm_len);

            // Male joins — straight ends, or at mitered arm tips
            if (kind_start == "male") {
                if (corner_start)
                    rim_corner_join_start(arm_len, "male");
                else
                    edge_end_join(
                        z_pos = edge_join_z_start("male"),
                        kind = "male",
                        turn90 = corner_miter_start
                    );
            }
            if (kind_finish == "male") {
                if (corner_finish)
                    translate([0, 0, length])
                        rim_corner_join_finish(arm_len, "male");
                else
                    edge_end_join(
                        z_pos = edge_join_z_finish("male", length),
                        kind = "male",
                        turn90 = corner_miter_finish
                    );
            }
        }

        // Female joins — cut pockets out of the main rim (and any unioned solids)
        if (kind_start == "female") {
            if (corner_start)
                rim_corner_join_start(arm_len, "female");
            else
                edge_end_join(
                    z_pos = edge_join_z_start("female"),
                    kind = "female",
                    turn90 = corner_miter_start
                );
        }
        if (kind_finish == "female") {
            if (corner_finish)
                translate([0, 0, length])
                    rim_corner_join_finish(arm_len, "female");
            else
                edge_end_join(
                    z_pos = edge_join_z_finish("female", length),
                    kind = "female",
                    turn90 = corner_miter_finish
                );
        }
    }
}

// ---------------------------------------------------------------------------
// Corner-in-rim: two segments with independent lengths meeting at a 45° miter
// ---------------------------------------------------------------------------
//
// QUICK REFERENCE — rim_corner_assembly(...)
//   length_a     segment along +Z before the corner (mm) — total length
//   length_b     mitered arm along -X after the corner (mm) — total length
//                (includes the W miter band; free run = length_b − W)
//   join_a       free start of A: 0=none, 1=male, 2=female
//   join_b       free tip of B arm: 0=none, 1=male, 2=female
//   cord_hole_on / ingress_on / cord_under_on
//                "a" | "b" — place that feature on segment A or B (default "a")
//   ingress_length  0 = off; otherwise >= edge_ingress_length_min
//                   (clear opening; bay pads +2W for the perpendicular miters)
//   Single fused solid — integrated 45° corner arm (no separate B start miter).
//
// Frame for features on free length_b (past the W miter overlap on the arm).
module rim_corner_b_frame(length_a) {
    W = edge_profile_max_x;
    translate([0, 0, length_a])
    translate([W, 0, -W])
    rotate([0, -90, 0])
        children();
}

// Local free-arm origin: skip the W miter band.
// Feature z ∈ [0, length_b − W] with tip at free z = length_b − W.
module rim_corner_b_free(length_a) {
    W = edge_profile_max_x;
    rim_corner_b_frame(length_a)
    translate([0, 0, W])
        children();
}

module rim_corner_assembly(
    length_a = 80,
    length_b = 80,
    join_a = 0,   // 0 none, 1 male, 2 female — free start of A
    join_b = 0,   // 0 none, 1 male, 2 female — free tip of B arm
    cord_hole = undef,
    cord_hole_inner_d = undef,
    cord_hole_pos = undef,
    cord_hole_on = "a",   // "a" | "b"
    cord_under = undef,
    cord_under_gap_len = undef,
    cord_under_on = "a",  // "a" | "b"
    lid_ingress = undef,
    ingress_depth = undef,
    ingress_length = undef,
    ingress_remove_right_rim = undef,
    glass_sit = undef,
    ingress_z_center = undef,
    ingress_on = "a"      // "a" | "b"
) {
    assert(join_a == 0 || join_a == 1 || join_a == 2, "join_a must be 0|1|2");
    assert(join_b == 0 || join_b == 1 || join_b == 2, "join_b must be 0|1|2");
    assert(length_a > 0 && length_b > 0, "segment lengths must be > 0");
    assert(cord_hole_on == "a" || cord_hole_on == "b",
        "cord_hole_on must be \"a\" or \"b\"");
    assert(ingress_on == "a" || ingress_on == "b",
        "ingress_on must be \"a\" or \"b\"");
    assert(cord_under_on == "a" || cord_under_on == "b",
        "cord_under_on must be \"a\" or \"b\"");

    in_len_raw = is_undef(ingress_length) ? edge_ingress_length : ingress_length;
    in_depth   = is_undef(ingress_depth) ? edge_ingress_depth : ingress_depth;
    in_no_rim  = is_undef(ingress_remove_right_rim)
                    ? edge_ingress_remove_right_rim : ingress_remove_right_rim;
    do_glass   = is_undef(glass_sit) ? edge_ingress_glass_sit : glass_sit;
    in_zc      = is_undef(ingress_z_center) ? undef : ingress_z_center;

    do_cord    = is_undef(cord_hole) ? edge_cord_hole_enable : cord_hole;
    do_under   = is_undef(cord_under) ? edge_cord_under_enable : cord_under;
    // ingress_length 0 = off (even if lid_ingress is true)
    do_ingress = (is_undef(lid_ingress) ? edge_ingress_enable : lid_ingress)
                    && (in_len_raw > 0);

    cord_on_a    = do_cord && cord_hole_on == "a";
    cord_on_b    = do_cord && cord_hole_on == "b";
    under_on_a   = do_under && cord_under_on == "a";
    under_on_b   = do_under && cord_under_on == "b";
    ingress_on_a = do_ingress && ingress_on == "a";
    ingress_on_b = do_ingress && ingress_on == "b";

    hole_inner_d = is_undef(cord_hole_inner_d) ? edge_cord_hole_inner_d : cord_hole_inner_d;
    hole_pos     = is_undef(cord_hole_pos) ? edge_cord_hole_pos : cord_hole_pos;
    under_gap    = is_undef(cord_under_gap_len) ? edge_cord_under_gap_len : cord_under_gap_len;

    W_b = edge_profile_max_x;
    // length_b is total arm length (like length_a); free run past miter band:
    free_len_b = length_b - W_b;
    assert(free_len_b > 0,
        str("length_b must be > profile width ", W_b, " (got ", length_b, ")"));

    // Padded bay length used by edge_lid_ingress / bay cutters.
    // ingress_length = clear opening; +2W for the perpendicular arm miters.
    bay_len = in_len_raw + 2 * W_b;
    zc_b    = is_undef(in_zc) ? free_len_b / 2 : in_zc;
    z0_b    = zc_b - bay_len / 2;
    z1_b    = zc_b + bay_len / 2;

    if (ingress_on_b) {
        assert(in_len_raw >= edge_ingress_length_min,
            str("ingress_length must be 0 (off) or >= ", edge_ingress_length_min,
                " so bay miters do not interact (got ", in_len_raw, ")"));
        assert(z0_b >= 0 && z1_b <= free_len_b,
            str("ingress on B must fit in free length ", free_len_b,
                " (length_b=", length_b, " − W=", W_b,
                "; bay padded=", bay_len, " z=[", z0_b, ",", z1_b, "])"));
    }

    // Integrated corner arm on A (original B corner miter from rim_corner_arm_finish).
    // Ingress on B: bay-cut the free arm first, then union ingress arms/back so
    // the bay cutter cannot slice the perpendicular miters (kept the A↔B corner).
    difference() {
        union() {
            difference() {
                union() {
                    rim_piece_assembly(
                        length = length_a,
                        edge_join_ends = 0,
                        cornerpiecenum = 3,
                        corner_arm_length = length_b,
                        cord_hole = cord_on_a,
                        cord_hole_inner_d = cord_hole_inner_d,
                        cord_hole_pos = cord_hole_pos,
                        cord_under = under_on_a,
                        cord_under_gap_len = cord_under_gap_len,
                        lid_ingress = ingress_on_a,
                        ingress_depth = ingress_depth,
                        ingress_length = ingress_on_a ? in_len_raw : 0,
                        ingress_remove_right_rim = ingress_remove_right_rim,
                        glass_sit = glass_sit,
                        ingress_z_center = ingress_z_center
                    );

                    if (cord_on_b)
                        rim_corner_b_free(length_a)
                            edge_cord_hole_feature(
                                free_len_b, hole_inner_d, hole_pos,
                                ingress_on_b, in_depth, bay_len, in_zc
                            );
                }

                // Cut bay into B arm body only (before appending ingress arms).
                if (ingress_on_b)
                    rim_corner_b_free(length_a)
                        edge_ingress_bay_opening_cut(
                            z0_b, z1_b, in_depth, bay_len, in_no_rim, zc_b
                        );

                if (under_on_b)
                    rim_corner_b_free(length_a)
                        edge_cord_under_cut(free_len_b, under_gap, edge_cord_under_keep_below);
            }

            // Perpendicular ingress arms + back — unioned after the bay cut.
            if (ingress_on_b) {
                rim_corner_b_free(length_a) {
                    edge_ingress_arm_near(z0_b, in_depth, bay_len, in_no_rim, do_glass);
                    edge_ingress_arm_far(z1_b, in_depth, bay_len, in_no_rim, do_glass);
                    edge_ingress_back(z0_b, z1_b, in_depth, bay_len, in_no_rim);
                }
            }

            if (join_a == 1)
                edge_end_join(z_pos = edge_join_z_start("male"), kind = "male");
            if (join_b == 1)
                translate([0, 0, length_a])
                    rim_corner_join_finish(length_b, "male");
        }

        if (join_a == 2)
            edge_end_join(z_pos = edge_join_z_start("female"), kind = "female");
        if (join_b == 2)
            translate([0, 0, length_a])
                rim_corner_join_finish(length_b, "female");
    }
}

// Alias used by older demos / fit preview wording
module edgereplica(
    length = edge_default_length,
    stem_gripper_sides = 0,
    edge_join_ends = undef,
    cord_hole = undef,
    cord_hole_inner_d = undef,
    cord_hole_pos = undef,
    cord_under = undef,
    cord_under_gap_len = undef,
    lid_ingress = undef,
    ingress_depth = undef,
    ingress_length = undef,
    ingress_remove_right_rim = undef,
    glass_sit = undef,
    ingress_z_center = undef,
    cornerpiecenum = 0
) {
    rim_piece_assembly(
        length = length,
        stem_gripper_sides = stem_gripper_sides,
        edge_join_ends = edge_join_ends,
        cord_hole = cord_hole,
        cord_hole_inner_d = cord_hole_inner_d,
        cord_hole_pos = cord_hole_pos,
        cord_under = cord_under,
        cord_under_gap_len = cord_under_gap_len,
        lid_ingress = lid_ingress,
        ingress_depth = ingress_depth,
        ingress_length = ingress_length,
        ingress_remove_right_rim = ingress_remove_right_rim,
        glass_sit = glass_sit,
        ingress_z_center = ingress_z_center,
        cornerpiecenum = cornerpiecenum
    );
}
