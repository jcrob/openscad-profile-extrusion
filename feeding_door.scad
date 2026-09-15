// Feeding door — dual spline rims, print-in-place hinge, sit-on latch.
// Included from rim_piece_assembly.scad (uses its profile constants).
//
// Outer spline U: same no-right-rim profile as ingress (inner spline of the
// current rim). Continuous with the main tank screen. Glass-sit is NOT cut.
// Inner door: rectangle of that same spline profile, hinged to the main rim
// with a BOSL2-style print-in-place knuckle hinge (in_place cones).
// Latch: sit-on tab on the door; matching pocket on the inner face of the
// outer back wall.

/* [4) Feeding door — dual spline rims + print-in-place hinge] */
edge_feeding_enable      = false;
edge_feeding_opening     = 70.0;  // clear inner opening along the piece (mm)
edge_feeding_depth       = 40.0;  // inner cavity into the tank (mm)
edge_feeding_z_center    = undef;
edge_feeding_gap         = 0.45;  // clearance around the inner door
edge_feeding_hinge_d     = 5.0;
edge_feeding_hinge_segs  = 7;
edge_feeding_hinge_gap   = 0.28;
edge_feeding_latch_w     = 10.0;
edge_feeding_latch_t     = 2.4;
edge_feeding_latch_sit   = 3.2;
edge_feeding_latch_clear = 0.35;

function feeding_spline_w() = edge_stem_root_right;

function feeding_bay(opening) =
    opening > 0 ? opening + 2 * feeding_spline_w() : 0;

function feeding_outer_depth(depth) =
    depth + feeding_spline_w();

// ---------------------------------------------------------------------------
// BOSL2 knuckle_hinge(in_place=true) compatible subset
// Axis along +Z through the origin. Mount is the YZ plane (flange).
// If BOSL2 is on OPENSCADPATH you can replace these with:
//   include <BOSL2/std.scad>
//   include <BOSL2/hinges.scad>
//   knuckle_hinge(..., in_place=true)
// ---------------------------------------------------------------------------

module feeding_knuckle_leaf(
    length,
    segs = edge_feeding_hinge_segs,
    knuckle_diam = edge_feeding_hinge_d,
    gap = edge_feeding_hinge_gap,
    inner = false,
    cone_ang = 45
) {
    n = max(3, segs);
    pitch = length / n;
    pin_d = knuckle_diam - 1;
    cone_h = max(0.8, (pin_d / 2) / tan(cone_ang));
    for (i = [0 : n - 1]) {
        mine = inner ? (i % 2 == 1) : (i % 2 == 0);
        if (mine) {
            z0 = i * pitch;
            difference() {
                translate([0, 0, z0 + gap / 2])
                    cylinder(d = knuckle_diam, h = pitch - gap, $fn = 28);
                // Female cones where the other leaf's male enters
                if (i > 0 && ((i - 1) % 2 == 1) == inner) {
                    translate([0, 0, z0 + gap / 2 - 0.01])
                        cylinder(
                            d1 = pin_d + 2 * gap,
                            d2 = 0.3,
                            h = cone_h + gap + 0.02,
                            $fn = 20
                        );
                }
                if (i < n - 1 && ((i + 1) % 2 == 1) == inner) {
                    translate([0, 0, z0 + pitch - gap / 2 - cone_h - gap + 0.01])
                        cylinder(
                            d1 = 0.3,
                            d2 = pin_d + 2 * gap,
                            h = cone_h + gap + 0.02,
                            $fn = 20
                        );
                }
            }
            // Male cones into the neighboring other-leaf knuckle
            if (i < n - 1 && ((i + 1) % 2 == 1) != inner) {
                translate([0, 0, z0 + pitch - gap / 2])
                    cylinder(d1 = pin_d, d2 = 0.35, h = cone_h, $fn = 20);
            }
            if (i > 0 && ((i - 1) % 2 == 1) != inner) {
                translate([0, 0, z0 + gap / 2])
                mirror([0, 0, 1])
                    cylinder(d1 = pin_d, d2 = 0.35, h = cone_h, $fn = 20);
            }
        }
    }
}

module feeding_pip_hinge(length) {
    union() {
        feeding_knuckle_leaf(length, inner = false);
        feeding_knuckle_leaf(length, inner = true);
    }
}

// ---------------------------------------------------------------------------
// Spline-only cut: open the left flange/stem in the bay; glass-sit stays.
// ---------------------------------------------------------------------------

module feeding_spline_bay_cut(z0, z1) {
    j  = edge_ingress_joint;
    sw = feeding_spline_w();
    y0 = -edge_overall_height - 1;
    yh = edge_overall_height + edge_top_ridge_grip_h + 2;
    if (z1 > z0)
        translate([-j, y0, z0])
            cube([sw + 2 * j, yh, z1 - z0]);
}

// ---------------------------------------------------------------------------
// Sit-on latch: tab on the door, pocket on the inner face of the outer back.
// ---------------------------------------------------------------------------

module feeding_latch_tab(z_mid, x_face) {
    w = edge_feeding_latch_w;
    t = edge_feeding_latch_t;
    s = edge_feeding_latch_sit;
    translate([x_face - s, -t, z_mid - w / 2])
        cube([s + 0.4, t, w]);
}

module feeding_latch_pocket(z_mid, x_face) {
    c = edge_feeding_latch_clear;
    w = edge_feeding_latch_w;
    t = edge_feeding_latch_t;
    s = edge_feeding_latch_sit;
    translate([x_face - s - c, -t - c, z_mid - w / 2 - c])
        cube([s + c + 0.6, t + 2 * c, w + 2 * c]);
}

// ---------------------------------------------------------------------------
// Inner door: rectangle of the same no-right-rim spline as the outer U.
// ---------------------------------------------------------------------------

module feeding_inner_rect(x_near, x_far, z0, z1) {
    sw = feeding_spline_w();
    j  = edge_ingress_joint;
    len_z = z1 - z0;
    len_x = x_near - x_far;
    if (len_z > sw && len_x > sw) {
        translate([x_near, 0, 0])
            edge_run_z(z0 - j, len_z + 2 * j, true);
        translate([x_far, 0, 0])
            edge_run_z(z0 - j, len_z + 2 * j, true);
        translate([x_near, 0, 0])
            edge_run_neg_x(z0, len_x + sw + j, false, true);
        translate([x_near, 0, 0])
            edge_run_neg_x(z1, len_x + sw + j, true, true);
    }
}

// Rail on the remaining glass-sit inner face so outer PIP knuckles fuse to
// the main rim after the spline bay is opened. Stays in the cut spline band.
module feeding_hinge_mount(z0, z1) {
    sw = feeding_spline_w();
    hd = edge_feeding_hinge_d;
    if (z1 > z0)
        translate([0, -hd, z0])
            cube([sw + 0.6, hd, z1 - z0]);
}

// ---------------------------------------------------------------------------
// Full feeding-door feature on a straight (or local) rim run along +Z.
// ---------------------------------------------------------------------------

module edge_feeding_door(length, opening, depth, z_center = undef,
    clear_start = 0, clear_finish = 0
) {
    sw = feeding_spline_w();
    gap = edge_feeding_gap;
    zc = is_undef(z_center) ? length / 2 : z_center;
    bay = feeding_bay(opening);
    z0 = zc - bay / 2;
    z1 = zc + bay / 2;
    outer_d = feeding_outer_depth(depth);

    assert(opening > 0, "feeding opening must be > 0");
    assert(z0 >= clear_start && z1 <= length - clear_finish,
        str("feeding door bay [", z0, ",", z1, "] out of range for length ",
            length, " clear=", clear_start, "/", clear_finish));
    assert(outer_d > sw + 4, "feeding depth too small for spline back wall");

    // Inner door sits inside the outer U, fully in the tank (no overlap
    // with the remaining glass-sit). Near bar occupies [-sw-gap, -gap].
    z0d = z0 + sw + gap;
    z1d = z1 - sw - gap;
    x_near = -sw - gap;
    x_far  = -(outer_d - sw - gap);
    hinge_len = z1d - z0d;
    z_mid = (z0d + z1d) / 2;
    x_back_inner = -outer_d + sw;

    difference() {
        union() {
            // Outer spline U (ingress layout, remove_right_rim, no glass-sit cut)
            edge_ingress_arms_back(z0, z1, outer_d, bay, true, false);

            // Inner spline rectangle
            feeding_inner_rect(x_near, x_far, z0d, z1d);

            // Mount + PIP hinge join the door to the main rim
            feeding_hinge_mount(z0d, z1d);
            translate([0, -edge_feeding_hinge_d / 2, z0d])
                feeding_pip_hinge(hinge_len);

            // Sit-on latch tab on the inner door far bar
            feeding_latch_tab(z_mid, x_far);
        }
        feeding_latch_pocket(z_mid, x_back_inner);
    }
}

module edge_feeding_spline_cut_only(length, opening, depth, z_center = undef) {
    zc = is_undef(z_center) ? length / 2 : z_center;
    bay = feeding_bay(opening);
    feeding_spline_bay_cut(zc - bay / 2, zc + bay / 2);
}
