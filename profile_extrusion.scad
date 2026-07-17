// Extruded profile from dimensioned cross-section sketch
// Units: millimeters
//
// Labeled dimensions:
//   overall top width ........ 13.8
//   overall height ........... 26.8
//   top bar thickness ........  1.3
//   left flange depth ........ 11.0
//   flat under top (L) .......  2.68   // between flange inner top and stem root
//   right top segment width ..  7.4
//   right notch depth ........  2.4
//   stem tip width ...........  0.95
//
// Assumptions (not labeled on sketch):
//   left flange thickness = top bar thickness (1.3)
//   stem root spans from end of left flat to right-notch inner face
//   stem tapers linearly to the tip, centered on that root span
//
// Origin: top-left corner of the profile. +Y is up (features extend in -Y).

/* [Extrusion] */
length = 50; // length along Z

/* [Drawing dimensions] */
top_width       = 13.8;
overall_height  = 26.8;
top_thickness   = 1.3;
left_flange_h   = 11.0;
left_flat_w     = 2.68; // underside gap: flange inner top → stem root left
right_segment_w = 7.4;
right_notch_h   = 2.4;
stem_tip_w      = 0.95;
left_flange_t   = top_thickness;

notch_inner_x  = top_width - right_segment_w;
stem_root_left = left_flange_t + left_flat_w;
stem_root_w    = notch_inner_x - stem_root_left;
tip_center_x   = stem_root_left + stem_root_w / 2;
tip_left_x     = tip_center_x - stem_tip_w / 2;
tip_right_x    = tip_center_x + stem_tip_w / 2;

// Counter-clockwise outline (OpenSCAD convention)
profile_points = [
    [0,               0],                 // top-left
    [0,              -left_flange_h],     // left flange outer bottom
    [left_flange_t,  -left_flange_h],     // left flange inner bottom
    [left_flange_t,  -top_thickness],     // top of left flange (underside)
    [stem_root_left, -top_thickness],     // end of 2.68 flat / stem root left
    [tip_left_x,     -overall_height],    // stem tip left
    [tip_right_x,    -overall_height],    // stem tip right
    [notch_inner_x,  -top_thickness],     // stem root right / underside
    [notch_inner_x,  -right_notch_h],     // right notch inner bottom
    [top_width,      -right_notch_h],     // right outer bottom of notch
    [top_width,       0],                 // top-right
];

linear_extrude(height = length, convexity = 4)
    polygon(points = profile_points);
