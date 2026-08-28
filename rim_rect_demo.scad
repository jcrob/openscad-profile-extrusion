// Demo entry for rim_rectangular_lid.scad
RIM_RECT_LIB_ONLY = true;
include <rim_rectangular_lid.scad>

/* [Demo] */
demo_layout = "assembled"; // "assembled" | "blowout" | "plate"
demo_glass_w = 900;
demo_glass_d = 600;

rim_rectangular_lid(
    layout = demo_layout,
    glass_w = demo_glass_w,
    glass_d = demo_glass_d
);
