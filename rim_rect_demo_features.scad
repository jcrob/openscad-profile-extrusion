// Example: 400×300 mm lid with corner ingress + middle cord hole on south side.
RIM_RECT_LIB_ONLY = true;
include <rim_rectangular_lid.scad>

glass_width = 400;
glass_depth = 300;

corner_features = [
    rim_feat(ingress = true, ingress_len = 40, ingress_on = "a"),  // SW
    RIM_FEAT_NONE,
    RIM_FEAT_NONE,
    rim_feat(cord_hole = true, cord_d = 10, cord_on = "b")         // NW
];

side_features_s = [
    RIM_FEAT_NONE,
    rim_feat(cord_hole = true, cord_pos = "middle")  // middle south segment
];

rim_rectangular_lid(
    glass_w = glass_width,
    glass_d = glass_depth,
    layout = "blowout",
    corners = corner_features,
    side_feats_s = side_features_s
);
