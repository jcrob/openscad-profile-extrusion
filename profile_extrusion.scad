// Extruded profile from dimensioned cross-section sketch
// Units: millimeters
//
// Labeled dimensions:
//   overall top width ........ 13.8
//   overall height ........... 26.8
//   top bar / left flat t ....  1.9
//   left flange depth ........ 11.0
//   left flange tip thickness   1.16
//   left flange tip right x ..  3.2   // bends toward stem
//   flat under top (L) .......  3.4   // flange inner top → stem root left
//   stem root width ..........  3.8
//   right segment tip t ......  1.16  // tapers upward toward outer tip
//   stem tip width ...........  0.95
//
// Assumptions:
//   left flange root thickness = top bar thickness (1.9)
//   left flange outer/inner edges taper linearly to the tip
//   stem root is 3.8 wide after the left flat; tapers to stem tip
//   right segment vertical thickness = left-flat thickness at stem side,
//     tapering upward to 1.16 at the outer tip
//
// Origin: top-left corner of the profile. +Y is up (features extend in -Y).

/* [Extrusion] */
length = 50; // length along Z

/* [Drawing dimensions] */
top_width             = 13.8;
overall_height        = 26.8;
top_thickness         = 1.9;
left_flange_h         = 11.0;
left_flat_w           = 3.4;  // underside gap: flange inner top → stem root left
stem_root_w           = 3.8;
stem_tip_w            = 0.95;
left_flange_t         = top_thickness;
left_flange_tip_t     = 1.16; // flange thickness at tip
left_flange_tip_right = 3.2;  // flange tip inner (right) X — bent toward stem
right_segment_tip_t   = 1.16; // right segment thickness at outer tip
left_flat_t           = top_thickness; // vertical thickness of left flat / top bar
right_segment_root_t  = left_flat_t;   // thickest at left, next to stem root

left_flange_tip_left = left_flange_tip_right - left_flange_tip_t;
stem_root_left       = left_flange_t + left_flat_w;
stem_root_right      = stem_root_left + stem_root_w;
tip_center_x         = stem_root_left + stem_root_w / 2;
tip_left_x           = tip_center_x - stem_tip_w / 2;
tip_right_x          = tip_center_x + stem_tip_w / 2;

// Counter-clockwise outline (OpenSCAD convention)
profile_points = [
    [0,                      0],                      // top-left
    [left_flange_tip_left,  -left_flange_h],          // left flange outer tip
    [left_flange_tip_right, -left_flange_h],          // left flange inner tip (x=3.2)
    [left_flange_t,         -left_flat_t],            // left flange inner top
    [stem_root_left,        -left_flat_t],            // end of left flat / stem root left
    [tip_left_x,            -overall_height],         // stem tip left
    [tip_right_x,           -overall_height],         // stem tip right
    [stem_root_right,       -right_segment_root_t],   // stem root right / right seg thickest
    [top_width,             -right_segment_tip_t],    // right segment tip (1.16)
    [top_width,              0],                      // top-right
];

linear_extrude(height = length, convexity = 4)
    polygon(points = profile_points);
