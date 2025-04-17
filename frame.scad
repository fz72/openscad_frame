// ==== Parameters ====
length = 59;         // Length (X)
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
corner_length = 82.5;

add_holes = true;       // Enable/disable holes in the middle
hole_diameter = 3;      // Diameter of the hole
hole_depth = 5;        // Depth of the hole


strip_pattern = false;  // Create stripe pattern
strip_spacing = 4;
strip_width = 0.5;

split_at_groove = true;
split_tenon_count = 2;
split_tenon_radius = 2;
split_tenon_height = 2;
split_tenon_inner_percent = 0.98;


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

module generate_base(length, width, height, corner_part, corner_length) {
    // --- Base cube ---
    cube([length, width, height]);

    // --- Add corner part if enabled ---
    if (corner_part) {
        translate([width, 0, 0])
            rotate([0, 0, 90])  // 90 degree rotation around Y-axis
                cube([corner_length, width, height]);
    }
}

module generate_split_tenon(split_tenon_count, split_tenon_distance, corner_part, split_tenon_distance_corner, split_tenon_width_pos, split_tenon_height, split_tenon_radius, height) {
    for(i = [1: 1 : split_tenon_count]) {
                    translate([(split_tenon_distance * i) - split_tenon_distance / 2, split_tenon_width_pos, height])
                        cylinder(h = split_tenon_height, r = split_tenon_radius, center = false, $fn = 64);
                }
                
                if (corner_part) {
                    for(i = [1: 1 : split_tenon_count]) {
                        translate([split_tenon_width_pos, (split_tenon_distance_corner * i) - split_tenon_distance_corner / 2, height])
                            cylinder(h = split_tenon_height, r = split_tenon_radius, center = false, $fn = 64);
                    }
                }
}

// ==== Main Module ====
module frame_with_joining(length, width, height, groove_height, groove_depth, groove_pos_height, tenon_width, tenon_height, tenon_depth, tenon_radius, add_holes, hole_diameter, hole_depth, corner_part, corner_length, split_at_groove, split_tenon_count, split_tenon_radius, split_tenon_height, split_tenon_inner_percent) {
    
    // calculate variables
    split_height = groove_pos_height+groove_height;
    
    split_tenon_height = ( height - split_height ) * 0.7;
    split_tenon_width_pos = (width - groove_depth) / 2;
    split_tenon_distance = length / split_tenon_count;
    split_tenon_distance_corner = corner_length / split_tenon_count;
    
    difference() {
        union() {
            
            
            if (split_at_groove) {
                generate_base(length, width, split_height, corner_part, corner_length);
                translate([length * 2, 0, 0])
                    generate_base(length, width, height - split_height, corner_part, corner_length);
            }
            else {
                generate_base(length, width, height, corner_part, corner_length);
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
            
            
            // -- Tenon for connection --
            if (split_at_groove) {
                generate_split_tenon(split_tenon_count, split_tenon_distance, corner_part,split_tenon_distance_corner, split_tenon_width_pos, split_tenon_height, split_tenon_radius*split_tenon_inner_percent, split_height);
            }
            
            
            // --- Diagonal stripes on top ---
            if (strip_pattern) {
                if (split_at_groove) {
                    translate([length * 2, 0, 0])
                        diagonal_stripe_area(0, 0, corner_part, length, width, corner_length, height-split_height, strip_spacing, strip_width);
                }
                else {
                    diagonal_stripe_area(0, 0, corner_part, length, width, corner_length, height, strip_spacing, strip_width);
                }
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
        
        // -- Tenon for connection --
        if (split_at_groove) {
            translate([length * 2, 0, 0])
                generate_split_tenon(split_tenon_count, split_tenon_distance, corner_part,split_tenon_distance_corner, split_tenon_width_pos, split_tenon_height, split_tenon_radius, 0);
        }
        
    }
}

// ==== Call ====
frame_with_joining(
    length, width, height,
    groove_height, groove_depth, groove_pos_height,
    tenon_width, tenon_height, tenon_depth, tenon_radius,
    add_holes, hole_diameter, hole_depth,
    corner_part, corner_length,
    split_at_groove, split_tenon_count, split_tenon_radius, split_tenon_height, split_tenon_inner_percent
);
