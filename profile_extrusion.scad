// Extruded profile from dimensioned cross-section sketch
// Units: millimeters
//
// Labeled dimensions:
//   overall top width ........ 13.8
//   overall height ........... 26.8
//   top bar thickness ........  1.9
//   left flange depth ........ 11.0
//   left flange tip thickness   1.16
//   left flange tip right x ..  3.2   // bends toward stem
//   flat under top (L) .......  3.4   // flange inner top → stem root left
//   right top segment width ..  7.4
//   right tip segment width ..  1.0   // tapers at notch bottom
//   right notch depth ........  2.4
//   stem tip width ...........  0.95
//
// Assumptions:
//   left flange root thickness = top bar thickness (1.9)
//   left flange outer/inner edges taper linearly to the tip
//   stem root spans from end of left flat to right-segment inner at underside
//   stem tapers linearly to the tip, centered on that root span
//   right segment inner face tapers from 7.4 width at top to 1.0 at notch bottom
//
// Origin: top-left corner of the profile. +Y is up (features extend in -Y).

/* [Extrusion] */
length = 50; // length along Z

/* [Drawing dimensions] */
top_width              = 13.8;
overall_height         = 26.8;
top_thickness          = 1.9;
left_flange_h          = 11.0;
left_flat_w            = 3.4;  // underside gap: flange inner top → stem root left
right_segment_w        = 7.4;
right_notch_h          = 2.4;
stem_tip_w             = 0.95;
left_flange_t          = top_thickness;
left_flange_tip_t      = 1.16; // flange thickness at tip
left_flange_tip_right  = 3.2;  // flange tip inner (right) X — bent toward stem
right_segment_tip_w    = 1.0;  // right lip width at notch bottom

left_flange_tip_left = left_flange_tip_right - left_flange_tip_t;
notch_inner_top_x    = top_width - right_segment_w;      // 7.4-wide at top / underside
notch_inner_bot_x    = top_width - right_segment_tip_w;  // 1.0-wide at notch bottom
stem_root_left       = left_flange_t + left_flat_w;
stem_root_right      = notch_inner_top_x;
stem_root_w          = stem_root_right - stem_root_left;
tip_center_x         = stem_root_left + stem_root_w / 2;
tip_left_x           = tip_center_x - stem_tip_w / 2;
tip_right_x          = tip_center_x + stem_tip_w / 2;

// Counter-clockwise outline (OpenSCAD convention)
profile_points = [
    [0,                     0],                 // top-left
    [left_flange_tip_left, -left_flange_h],     // left flange outer tip (tapered)
    [left_flange_tip_right,-left_flange_h],     // left flange inner tip (x=3.2)
    [left_flange_t,        -top_thickness],     // left flange inner top (underside)
    [stem_root_left,       -top_thickness],     // end of left flat / stem root left
    [tip_left_x,           -overall_height],    // stem tip left
    [tip_right_x,          -overall_height],    // stem tip right
    [stem_root_right,      -top_thickness],     // stem root right / right lip inner top
    [notch_inner_bot_x,    -right_notch_h],     // right lip inner at tip width 1.0
    [top_width,            -right_notch_h],     // right outer bottom of notch
    [top_width,             0],                 // top-right
];

linear_extrude(height = length, convexity = 4)
    polygon(points = profile_points);
