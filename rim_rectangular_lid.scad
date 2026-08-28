// Rectangular aquarium lid — rim frame from glass size + modular pieces.
// Uses rim_piece_assembly / rim_corner_assembly (max 200 mm per straight).
// Corner arms default to rim_max_piece_len (200 mm); remaining side runs are
// split into straight segments ≤ rim_max_piece_len with clockwise male/female joins.
//
// QUICK START
//   include <rim_rectangular_lid.scad>
//   rim_rectangular_lid();                    // assembled preview
//   rim_rectangular_lid(layout = "blowout");  // spread for inspection
//   rim_rectangular_lid(layout = "plate");    // 250×250 mm print bed pack
//
// FEATURE VECTORS (per corner or per side segment)
//   [0] cord_hole          bool
//   [1] cord_hole_inner_d  mm
//   [2] cord_hole_pos      "left"|"middle"|"right"
//   [3] cord_under         bool
//   [4] cord_under_gap_len mm
//   [5] lid_ingress        bool  (ingress_length > 0)
//   [6] ingress_length     mm (0 = off)
//   [7] ingress_depth      mm
//   [8] ingress_on         "a"|"b"  (corners only)
//   [9] cord_hole_on       "a"|"b"  (corners only)
//   [10] cord_under_on     "a"|"b"  (corners only)
//
//   RIM_FEAT_NONE = default row; override corner_features[0..3] (SW,SE,NE,NW)
//   and side_features[side][seg] for middle straight pieces on each side.

include <rim_piece_assembly.scad>

// Feature vector: see header comment block below.
RIM_FEAT_NONE = [
    false, 6, "middle",
    false, 20,
    false, 0, edge_ingress_depth, "a", "a", "a"
];

/* [Glass / frame] */
glass_width       = 600;   // inner opening along +X (mm)
glass_depth       = 450;   // inner opening along +Z (mm)
// glass_thickness is defined in rim_piece_assembly.scad (Customizer there or -D)

/* [Build limits] */
rim_max_piece_len = 200;   // max straight length (mm)
rim_corner_leg    = 0;     // 0 = use rim_max_piece_len (200 mm)

/* [Layout] */
rim_layout        = "assembled"; // "assembled" | "blowout" | "plate"
rim_plate_x       = 250;    // printable bed X (mm)
rim_plate_y       = 250;    // printable bed Y (mm)
rim_layout_gap    = 12;     // spacing between parts (mm)
rim_plate_margin  = 8;      // bed edge margin (mm)

/* [Corner features — SW, SE, NE, NW] */
corner_features = [
    RIM_FEAT_NONE,
    RIM_FEAT_NONE,
    RIM_FEAT_NONE,
    RIM_FEAT_NONE
];

/* [Side middle-segment features — [S, E, N, W] each a list per segment] */
side_features_s = [];
side_features_e = [];
side_features_n = [];
side_features_w = [];

// ---------------------------------------------------------------------------
// Feature helpers
// ---------------------------------------------------------------------------

function rim_feat_cord(f)        = f[0];
function rim_feat_cord_d(f)      = f[1];
function rim_feat_cord_pos(f)    = f[2];
function rim_feat_under(f)       = f[3];
function rim_feat_under_gap(f)   = f[4];
function rim_feat_ingress(f)     = f[5] && f[6] > 0;
function rim_feat_ingress_len(f) = f[6];
function rim_feat_ingress_dep(f) = f[7];
function rim_feat_ingress_on(f)  = f[8];
function rim_feat_cord_on(f)     = f[9];
function rim_feat_under_on(f)    = f[10];

function rim_side_feat_list(side_idx, lists) =
    side_idx == 0 ? lists[0] :
    side_idx == 1 ? lists[1] :
    side_idx == 2 ? lists[2] : lists[3];

function rim_side_feat(side_idx, seg_idx, lists) =
    let (
        row = rim_side_feat_list(side_idx, lists),
        n   = len(row)
    )
    (seg_idx < n) ? row[seg_idx] : RIM_FEAT_NONE;

function rim_corner_feat(corner_idx, corners = corner_features) =
    corners[corner_idx];

// ---------------------------------------------------------------------------
// Length / join planning
// ---------------------------------------------------------------------------

function rim_corner_leg_len(corner_leg = rim_corner_leg, max_len = rim_max_piece_len) =
    corner_leg > edge_profile_max_x ? corner_leg : max_len;

function rim_corner_feat_min_leg(f, corner_leg = rim_corner_leg) =
    rim_feat_ingress(f)
        ? max(rim_corner_leg_len(corner_leg), rim_feat_ingress_len(f) + 4)
        : rim_corner_leg_len(corner_leg);

function rim_rect_effective_corner_leg(corners = corner_features, corner_leg = rim_corner_leg) =
    let (
        mins = [ for (c = corners) rim_corner_feat_min_leg(c, corner_leg) ],
        base = rim_corner_leg_len(corner_leg)
    )
    len(mins) > 0 ? max(base, max(mins)) : base;

// Straight run between corner legs along one glass side.
function rim_side_straight_total(glass_dim, leg = undef, corners = corner_features) =
    let (leg_eff = is_undef(leg) ? rim_rect_effective_corner_leg(corners) : leg)
    max(0, glass_dim - 2 * leg_eff);

function rim_rect_partition(run_len, max_len = rim_max_piece_len) =
    let (
        n = max(1, ceil(run_len / max_len)),
        base = run_len / n
    )
    [ for (i = [0 : n - 1]) base ];

// edge_join_ends for a straight chained between female corner pockets.
function rim_rect_straight_joins(seg_idx, seg_count) =
    seg_count == 1 ? 2 :          // both male → two corners
    seg_idx == 0 ? 1 :            // male into corner, female to next
    seg_idx == seg_count - 1 ? 2 : // male from prev, male into corner
    1;                            // middle link

function rim_rect_side_dims(gw = glass_width, gd = glass_depth, corners = corner_features) = [
    rim_side_straight_total(gw, undef, corners),
    rim_side_straight_total(gd, undef, corners),
    rim_side_straight_total(gw, undef, corners),
    rim_side_straight_total(gd, undef, corners)
];

function rim_rect_side_seg_lens(side_idx, gw = glass_width, gd = glass_depth,
    max_len = rim_max_piece_len, corners = corner_features
) =
    let (
        dims = rim_rect_side_dims(gw, gd, corners),
        run  = dims[side_idx]
    )
    rim_rect_partition(run, max_len);

// ---------------------------------------------------------------------------
// Placement — native rim coords: path in XZ, profile in XY, Y = up
// Corners: SW=0, SE=1, NE=2, NW=3. Clockwise frame: S +X, E +Z, N -X, W -Z.
// Native rim_corner: A along +Z, B along -X after the miter.
// ---------------------------------------------------------------------------

// Clockwise joint pattern: female pockets on both free arms (join 2) receive
// male straight ends; straights chain male→female between segments.
function rim_rect_corner_joins(ci) = [2, 2];

module rim_rect_corner_pose(ci) {
    // SW: mirror so B runs +X (south); A runs +Z (west).
    if (ci == 0)
        mirror([1, 0, 0]) children();
    // SE: native A +Z (east), B -X (south).
    else if (ci == 1)
        children();
    // NE: A -Z (east), B -X (north).
    else if (ci == 2)
        rotate([0, 180, 0]) mirror([1, 0, 0]) children();
    // NW: A -Z (west), B +X (north).
    else
        rotate([0, 180, 0]) children();
}

function rim_rect_corner_pos(ci, gw = glass_width, gd = glass_depth) =
    ci == 0 ? [0, 0, 0] :
    ci == 1 ? [gw, 0, 0] :
    ci == 2 ? [gw, 0, gd] :
              [0, 0, gd];

module rim_rect_place_corner(ci, leg = undef, feat = undef,
    gw = glass_width, gd = glass_depth, corners = corner_features
) {
    leg_eff = is_undef(leg) ? rim_rect_effective_corner_leg(corners) : leg;
    f = is_undef(feat) ? rim_corner_feat(ci, corners) : feat;
    joins = rim_rect_corner_joins(ci);
    p = rim_rect_corner_pos(ci, gw, gd);
    translate(p)
    rim_rect_corner_pose(ci)
        rim_corner_assembly(
            length_a = leg_eff,
            length_b = leg_eff,
            join_a = joins[0],
            join_b = joins[1],
            cord_hole = rim_feat_cord(f),
            cord_hole_inner_d = rim_feat_cord_d(f),
            cord_hole_pos = rim_feat_cord_pos(f),
            cord_hole_on = rim_feat_cord_on(f),
            cord_under = rim_feat_under(f),
            cord_under_gap_len = rim_feat_under_gap(f),
            cord_under_on = rim_feat_under_on(f),
            lid_ingress = rim_feat_ingress(f),
            ingress_depth = rim_feat_ingress_dep(f),
            ingress_length = rim_feat_ingress_len(f),
            ingress_on = rim_feat_ingress_on(f)
        );
}

function rim_rect_side_yaw(side_idx) =
    side_idx == 0 ? 90 :
    side_idx == 1 ? 0 :
    side_idx == 2 ? -90 : 180;
function rim_rect_seg_offset(segs, seg_idx, acc = 0, i = 0) =
    i >= seg_idx ? acc : rim_rect_seg_offset(segs, seg_idx, acc + segs[i], i + 1);

module rim_rect_place_straight(side_idx, seg_idx, length, feat = undef,
    gw = glass_width, gd = glass_depth, leg = undef,
    side_feat_lists = [side_features_s, side_features_e, side_features_n, side_features_w],
    corners = corner_features
) {
    leg_eff = is_undef(leg) ? rim_rect_effective_corner_leg(corners) : leg;
    f = is_undef(feat)
        ? rim_side_feat(side_idx, seg_idx, side_feat_lists)
        : feat;
    segs = rim_rect_side_seg_lens(side_idx, gw, gd, rim_max_piece_len, corners);
    joins = rim_rect_straight_joins(seg_idx, len(segs));
    offset_along = leg_eff + rim_rect_seg_offset(segs, seg_idx);

    translate(
        side_idx == 0 ? [offset_along, 0, 0] :
        side_idx == 1 ? [gw, 0, offset_along] :
        side_idx == 2 ? [gw - offset_along, 0, gd] :
                        [0, 0, gd - offset_along]
    )
    rotate([0, rim_rect_side_yaw(side_idx), 0])
        rim_piece_assembly(
            length = length,
            edge_join_ends = joins,
            cord_hole = rim_feat_cord(f),
            cord_hole_inner_d = rim_feat_cord_d(f),
            cord_hole_pos = rim_feat_cord_pos(f),
            cord_under = rim_feat_under(f),
            cord_under_gap_len = rim_feat_under_gap(f),
            lid_ingress = rim_feat_ingress(f),
            ingress_depth = rim_feat_ingress_dep(f),
            ingress_length = rim_feat_ingress_len(f)
        );
}

module rim_rect_place_side(side_idx, gw = glass_width, gd = glass_depth,
    side_feat_lists = [side_features_s, side_features_e, side_features_n, side_features_w],
    corners = corner_features
) {
    segs = rim_rect_side_seg_lens(side_idx, gw, gd, rim_max_piece_len, corners);
    for (i = [0 : len(segs) - 1])
        rim_rect_place_straight(side_idx, i, segs[i],
            gw = gw, gd = gd, side_feat_lists = side_feat_lists, corners = corners);
}

// ---------------------------------------------------------------------------
// Print / blowout layout
// ---------------------------------------------------------------------------

// Lay a path-length piece flat on the bed (profile height → +Z).
module rim_rect_print_flat() {
    rotate([90, 0, 0])
        children();
}

function rim_rect_straight_footprint(len) = [len, edge_overall_height + 2];
function rim_rect_corner_footprint(leg) = [2 * leg + edge_profile_max_x, edge_overall_height + 2];

// Build a feature row (see header for field order).
function rim_feat(
    cord_hole = false, cord_d = 6, cord_pos = "middle",
    cord_under = false, under_gap = 20,
    ingress = false, ingress_len = 0, ingress_dep = edge_ingress_depth,
    ingress_on = "a", cord_on = "a", under_on = "a"
) = [
    cord_hole, cord_d, cord_pos,
    cord_under, under_gap,
    ingress, ingress_len, ingress_dep,
    ingress_on, cord_on, under_on
];

module rim_rect_draw_plate_outline() {
    color([0.75, 0.75, 0.8, 0.25])
        translate([0, 0, -0.4])
            cube([rim_plate_x, rim_plate_y, 0.2]);
    %translate([rim_plate_margin, rim_plate_margin, 0])
        color([0.5, 0.8, 0.5, 0.15])
            cube([
                rim_plate_x - 2 * rim_plate_margin,
                rim_plate_y - 2 * rim_plate_margin,
                0.1
            ]);
}

module rim_rect_lid_assembled(gw = glass_width, gd = glass_depth,
    corners = corner_features,
    side_feat_lists = [side_features_s, side_features_e, side_features_n, side_features_w]
) {
    leg = rim_rect_effective_corner_leg(corners);
    for (ci = [0 : 3])
        rim_rect_place_corner(ci, leg, rim_corner_feat(ci, corners), gw, gd, corners);
    for (si = [0 : 3])
        rim_rect_place_side(si, gw, gd, side_feat_lists, corners);
}

module rim_rect_plate_item(part, leg, gw, gd, corners, side_feat_lists) {
    if (part[2] == "corner")
        rim_rect_place_corner(part[3], leg, rim_corner_feat(part[3], corners), gw, gd);
    else
        rim_rect_place_straight(part[3], part[4], part[5], side_feat_lists = side_feat_lists);
}

function rim_rect_pack_positions(parts, idx = 0, cx = rim_plate_margin, cy = rim_plate_margin,
    row_h = 0, out = []
) =
    idx >= len(parts) ? out :
    let (
        w = parts[idx][0],
        h = parts[idx][1],
        wrap = cx + w > rim_plate_x - rim_plate_margin,
        nx = wrap ? rim_plate_margin : cx,
        ny = wrap ? (cy + row_h + rim_layout_gap) : cy,
        nrh = wrap ? h : max(row_h, h),
        ncx = nx + w + rim_layout_gap
    )
    rim_rect_pack_positions(parts, idx + 1, ncx, ny, nrh, concat(out, [[nx, ny]]));

module rim_rect_blowout_corner(ci, leg, feat) {
    joins = rim_rect_corner_joins(ci);
    rim_rect_corner_pose(ci)
        rim_corner_assembly(
            length_a = leg,
            length_b = leg,
            join_a = joins[0],
            join_b = joins[1],
            cord_hole = rim_feat_cord(feat),
            cord_hole_inner_d = rim_feat_cord_d(feat),
            cord_hole_pos = rim_feat_cord_pos(feat),
            cord_hole_on = rim_feat_cord_on(feat),
            cord_under = rim_feat_under(feat),
            cord_under_gap_len = rim_feat_under_gap(feat),
            cord_under_on = rim_feat_under_on(feat),
            lid_ingress = rim_feat_ingress(feat),
            ingress_depth = rim_feat_ingress_dep(feat),
            ingress_length = rim_feat_ingress_len(feat),
            ingress_on = rim_feat_ingress_on(feat)
        );
}

module rim_rect_blowout_straight(side_idx, seg_idx, length, feat, seg_count) {
    joins = rim_rect_straight_joins(seg_idx, seg_count);
    rotate([0, rim_rect_side_yaw(side_idx), 0])
        rim_piece_assembly(
            length = length,
            edge_join_ends = joins,
            cord_hole = rim_feat_cord(feat),
            cord_hole_inner_d = rim_feat_cord_d(feat),
            cord_hole_pos = rim_feat_cord_pos(feat),
            cord_under = rim_feat_under(feat),
            cord_under_gap_len = rim_feat_under_gap(feat),
            lid_ingress = rim_feat_ingress(feat),
            ingress_depth = rim_feat_ingress_dep(feat),
            ingress_length = rim_feat_ingress_len(feat)
        );
}

module rim_rect_lid_blowout(gw = glass_width, gd = glass_depth,
    corners = corner_features,
    side_feat_lists = [side_features_s, side_features_e, side_features_n, side_features_w],
    gap = rim_layout_gap * 2
) {
    leg = rim_rect_effective_corner_leg(corners);
    corner_span = 2 * leg + edge_profile_max_x + gap;
    for (ci = [0 : 3])
        translate([ci * corner_span, 0, 0])
            rim_rect_blowout_corner(ci, leg, rim_corner_feat(ci, corners));

    y0 = corner_span + gap;
    row_h = rim_max_piece_len + gap;
    for (si = [0 : 3]) {
        segs = rim_rect_side_seg_lens(si, gw, gd, rim_max_piece_len, corners);
        for (i = [0 : len(segs) - 1])
            translate([
                rim_rect_seg_offset(segs, i) + i * gap,
                y0 + si * row_h,
                0
            ])
                rim_rect_blowout_straight(
                    si, i, segs[i],
                    rim_side_feat(si, i, side_feat_lists),
                    len(segs)
                );
    }
}

module rim_rect_lid_plate(gw = glass_width, gd = glass_depth,
    corners = corner_features,
    side_feat_lists = [side_features_s, side_features_e, side_features_n, side_features_w]
) {
    leg = rim_rect_effective_corner_leg(corners);
    rim_rect_draw_plate_outline();

    parts = concat(
        [ for (ci = [0 : 3])
            let (fp = rim_rect_corner_footprint(leg))
            [fp[0], fp[1], "corner", ci]
        ],
        [ for (si = [0 : 3])
            let (segs = rim_rect_side_seg_lens(si, gw, gd))
            for (i = [0 : len(segs) - 1])
                let (fp = rim_rect_straight_footprint(segs[i]))
                [fp[0], fp[1], "straight", si, i, segs[i]]
        ]
    );

    positions = rim_rect_pack_positions(parts);

    for (i = [0 : len(parts) - 1])
        translate([positions[i][0], positions[i][1], 0])
        rim_rect_print_flat()
            rim_rect_plate_item(parts[i], leg, gw, gd, corners, side_feat_lists);
}

// ---------------------------------------------------------------------------
// Main entry
// ---------------------------------------------------------------------------

module rim_rectangular_lid(
    glass_w = glass_width,
    glass_d = glass_depth,
    max_piece_len = rim_max_piece_len,
    layout = rim_layout,
    corners = corner_features,
    side_feats_s = side_features_s,
    side_feats_e = side_features_e,
    side_feats_n = side_features_n,
    side_feats_w = side_features_w
) {
    assert(glass_w > 2 * rim_rect_effective_corner_leg(corners), "glass_width too small for corners");
    assert(glass_d > 2 * rim_rect_effective_corner_leg(corners), "glass_depth too small for corners");

  // BOM echo
    leg = rim_rect_effective_corner_leg(corners);
    dims = rim_rect_side_dims(glass_w, glass_d, corners);
    echo(str(
        "Rim lid ", glass_w, "×", glass_d, " mm glass; corner leg=", leg,
        "; straight runs S/E/N/W=[",
        dims[0], ",", dims[1], ",", dims[2], ",", dims[3], "]"
    ));
    for (si = [0 : 3])
        echo(str("  side ", ["S","E","N","W"][si],
            " segments: ", rim_rect_side_seg_lens(si, glass_w, glass_d, max_piece_len)));

    lists = [side_feats_s, side_feats_e, side_feats_n, side_feats_w];

    if (layout == "assembled")
        rim_rect_lid_assembled(glass_w, glass_d, corners, lists);
    else if (layout == "blowout")
        rim_rect_lid_blowout(glass_w, glass_d, corners, lists);
    else if (layout == "plate")
        rim_rect_lid_plate(glass_w, glass_d, corners, lists);
    else
        assert(false, str("layout must be assembled|blowout|plate (got ", layout, ")"));
}

// Library include: set RIM_RECT_LIB_ONLY = true before include to skip auto-render.
if (is_undef(RIM_RECT_LIB_ONLY))
    rim_rectangular_lid();
