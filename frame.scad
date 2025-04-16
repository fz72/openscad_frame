// ==== Parameters ====
length = 53.5;         // Length (X)
width = 10;            // Width (Y)
height = 10;           // Height (Z)

groove_height = 1;     // Groove height (Z)
groove_depth = 2;      // Groove depth (Y)
groove_pos_height = 4.5; // Groove position height

tenon_width = 4;       // Tenon width (Y)
tenon_height = 4;      // Tenon height (Z)
tenon_depth = 5;       // Tenon depth (X)
tenon_radius = 3;      // Tenon radius

corner_part = true;    // Add corner part (true = yes, false = no)
corner_length = 77;

add_holes = true;       // Enable/disable holes in the middle
hole_diameter = 3;      // Diameter of the hole
hole_depth = 5;        // Depth of the hole


strip_pattern = false;  // Create stripe pattern
strip_spacing = 4;
strip_width = 0.5;




// ==== Stripe Module (limited area) ====
module diagonal_stripe_area(start_x, start_y, corner_part, length, width, corner_length, height, spacing, width_stripe) {
    
    // Calculate stripe length. If corner part is enabled, stripe must go beyond corner,
    // Otherwise it's enough to go along the tangent of a triangle
    helper_length = corner_part ? corner_length : width;
    stripe_length = sqrt(helper_length * helper_length + helper_length * helper_length);
        
    for (i = [0 : spacing : length + stripe_length]) {
        translate([start_x, start_y, height])
            intersection() {
                union(){
                    // --- Base cube ---
                    cube([length, width, height]);

                    // --- Add corner part if enabled ---
                    if (corner_part) {
                        translate([width, 0, 0])
                            rotate([0, 0, 90])  // 90 degree rotation around Y-axis
                                cube([corner_length, width, height]);
                    }
                }
                
                translate([i * -1 + length, 0, 0])
                    rotate([0, 0, -45])
                        cube([width_stripe, stripe_length, 0.5]);
            }
    }
}

// ==== Main Module ====
module frame_with_joining(length, width, height, groove_height, groove_depth, groove_pos_height, tenon_width, tenon_height, tenon_depth, tenon_radius, add_holes, hole_diameter, hole_depth, corner_part, corner_length) {
    difference() {
        union() {
            // --- Base cube ---
            cube([length, width, height]);

            // --- Add corner part if enabled ---
            if (corner_part) {
                translate([width, 0, 0])
                    rotate([0, 0, 90])  // 90 degree rotation around Y-axis
                        cube([corner_length, width, height]);
            }
            
            // --- Tenon at the beginning ---
            if (corner_part) {
                translate([(width - tenon_width)/2 + tenon_width, corner_length, 0])
                    rotate([0, 0, 90])  // 90 degree rotation around Z-axis for side tenon
                        cube([tenon_depth, tenon_width, tenon_height]);
                translate([width / 2, corner_length + tenon_depth, tenon_height / 2])
                    rotate([0, 0, 90])  // 90 degree rotation around Z-axis for side tenon
                        cylinder(h = tenon_height, r = tenon_radius, center = true);
            }
            else {
                translate([-tenon_depth, (width - tenon_width)/2, 0])
                    cube([tenon_depth, tenon_width, tenon_height]);
                translate([-tenon_depth, width / 2, tenon_height / 2])
                    cylinder(h = tenon_height, r = tenon_radius, center = true);
            }
            
            // --- Diagonal stripes on top ---
            if (strip_pattern) {
                diagonal_stripe_area(0, 0, corner_part, length, width, corner_length, height, strip_spacing, strip_width);
            }
        }
        
        // --- Tenon socket at the end ---
        translate([length - tenon_depth, (width - tenon_width)/2, 0])
            cube([tenon_depth, tenon_width, tenon_height]);
        translate([length - tenon_depth, width / 2, tenon_height / 2])
            cylinder(h = tenon_height, r = tenon_radius, center = true);
        
        // --- Inner groove ---
        if (corner_part) {
            translate([width, width - groove_depth, groove_pos_height])
                cube([length - width + groove_depth, groove_depth, groove_height]);
            
            translate([width, width - groove_depth, groove_pos_height])
                rotate([0, 0, 90])  // 90 degree rotation around Y-axis
                    cube([corner_length, groove_depth, groove_height]);
        }
        else {
            translate([0, width, groove_pos_height])
                cube([length, groove_depth, groove_height]);
        }
        
        
        // --- Holes in the middle ---
        if (add_holes) {
            // Hole
            translate([length / 2, ( width - groove_depth ) / 2, 0])
                cylinder(h = hole_depth, r = hole_diameter / 2, center = false, $fn = 64);
            
            if (corner_part) {
                // Hole on the right side (X = length)
                translate([( width - groove_depth ) / 2, corner_length / 2, 0])
                    cylinder(h = hole_depth, r = hole_diameter / 2, center = false, $fn = 64);
            }
        }
        
    }
}

// ==== Call ====
frame_with_joining(
    length, width, height,
    groove_height, groove_depth, groove_pos_height,
    tenon_width, tenon_height, tenon_depth, tenon_radius,
    add_holes, hole_diameter, hole_depth,
    corner_part, corner_length
);
