// Demo lid: distinct feature on each corner and side.
// Glass size = max glass-channel span (the pane). Ingress openings are the
// clear pass-through; bay length adds ~60 mm (2×profile).
RIM_RECT_LIB_ONLY = true;
include <rim_rectangular_lid.scad>

/* [Demo] */
demo_layout      = "blowout"; // "assembled" | "blowout" | "plate"
// Max glass-channel span (user measure). Frame offsets use profile width.
channel_width    = 900;
channel_depth    = 600;
// Clear ingress opening (mm). Bay = opening + pad (~60).
ingress_opening  = 40;

corner_features = [
    rim_feat(ingress = true, ingress_len = ingress_opening, ingress_dep = 30, ingress_on = "a"),
    rim_feat(cord_hole = true, cord_d = 8, cord_pos = "middle", cord_on = "b"),
    rim_feat(cord_under = true, under_gap = 24, under_on = "a"),
    rim_feat(ingress = true, ingress_len = ingress_opening, ingress_dep = 30, ingress_on = "b")
];

// 900×600 → S/N three segs (200+200+100), E/W one 200 mm seg.
// Ingress only on full-length pieces so opening+pad fits.
side_features_s = [
    rim_feat(ingress = true, ingress_len = ingress_opening, ingress_dep = 30),
    rim_feat(cord_under = true, under_gap = 20),
    rim_feat(cord_hole = true, cord_d = 8, cord_pos = "left")
];
side_features_e = [
    rim_feat(cord_hole = true, cord_d = 10, cord_pos = "right")
];
side_features_n = [
    RIM_FEAT_NONE,
    rim_feat(cord_under = true, under_gap = 28),
    rim_feat(cord_hole = true, cord_d = 6, cord_pos = "middle")
];
side_features_w = [
    rim_feat(ingress = true, ingress_len = ingress_opening, ingress_dep = 30)
];

rim_rectangular_lid(
    glass_w = channel_width,
    glass_d = channel_depth,
    layout  = demo_layout,
    corners = corner_features,
    side_feats_s = side_features_s,
    side_feats_e = side_features_e,
    side_feats_n = side_features_n,
    side_feats_w = side_features_w
);
