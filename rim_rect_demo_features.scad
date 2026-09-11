// Smaller example: 400×300 mm channel, SW ingress + south cord hole.
RIM_RECT_LIB_ONLY = true;
include <rim_rectangular_lid.scad>

/* [Demo] */
channel_width   = 400;  // max glass-channel span X
channel_depth   = 300;  // max glass-channel span Z
ingress_opening = 40;   // clear opening; bay adds ~60 mm

corner_features = [
    rim_feat(ingress = true, ingress_len = ingress_opening, ingress_on = "a"),
    RIM_FEAT_NONE,
    RIM_FEAT_NONE,
    rim_feat(cord_hole = true, cord_d = 10, cord_on = "b")
];

side_features_s = [
    rim_feat(cord_hole = true, cord_pos = "middle")
];

rim_rectangular_lid(
    glass_w = channel_width,
    glass_d = channel_depth,
    layout = "blowout",
    corners = corner_features,
    side_feats_s = side_features_s
);
