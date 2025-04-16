// ==== Parameters ====
ground_length = 20;         // Length (X)
ground_width = 35;            // Width (Y)
ground_height = 2;           // Height (Z)

support_length = 5;    // Length of the angled support (adjust as needed)
support_angle = 75;     // Angle of the support in degrees
support_height = 5;
support_diameter = 3 * 0.97;   // Should match or be slightly smaller than hole_diameter


// ==== Module: Rounded rectangle using Minkowski (2D only) ====
module rounded_rect_minkowski(length, width, radius) {
    minkowski() {
        square([length - 2*radius, width - 2*radius], center = true);
        circle(r = radius, $fn = 32);
    }
}

// ==== Module for the angled support ====
module angled_support(ground_length, ground_width, ground_height, support_length, support_angle, support_height, support_diameter) {
    union() {
        // Peg that goes into the frame hole
        // ==== Position the rounded object ====
        translate([0, ground_width / 2, ground_height / 2])
            linear_extrude(height = ground_height, center = true)
                rounded_rect_minkowski(ground_length, ground_width, 2);

            //cube([ground_length, ground_width, ground_height], center = true);
        translate([0, - ( cos( support_angle ) / support_diameter ) + support_diameter / 2  + (support_length / 2 ), support_height / 2])
            cube([support_diameter, support_diameter, support_height], center = true);

        // Angled support shaft
        translate([0, support_length*0.99, support_height*0.7])  // Move to the top of the peg
            rotate([support_angle, 0, 0])  // Tilt forward
                cylinder(h = support_length*2, r = support_diameter / 2, $fn = 64, center = false);
    }
}

// ==== Call the support ====
angled_support(ground_length, ground_width, ground_height, 
    support_length, support_angle, support_height, support_diameter);
