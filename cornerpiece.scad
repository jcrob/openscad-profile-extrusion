// Standalone corner print (pegged pair) — geometry from rim_piece_assembly.scad
include <rim_piece_assembly.scad>

// Print both halves; keep stem grippers for separate edge mating.
// Fit preview uses rim_piece_assembly via edge_fit_preview().
corner_print_pair(include_stem_grippers = true);
