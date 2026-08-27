// Demo entry for rim_rectangular_lid.scad
RIM_RECT_LIB_ONLY = true;
include <rim_rectangular_lid.scad>

/* [Demo] */
demo_layout = "assembled"; // "assembled" | "blowout" | "plate"

rim_rectangular_lid(layout = demo_layout);
