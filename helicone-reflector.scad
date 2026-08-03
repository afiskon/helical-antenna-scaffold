F_MHz = 2450;
Lambda_mm = (299792458 / (F_MHz*1000000))*1000;
max_width = 95;       // Maximum allowed width of the larger trapezoid base (mm)

// Make sure the bottom N-gon does not collapse inside the D1 circle
// The value 10 works OK for F_MHz in 1691..2450 range
// Set to 0 if preserving ideal cone angles is more important
d1_correction = 10;

// You can also experiment with D2 correction
// Personally I doubt that it affects much the overall antenna gain
d2_correction = 0;

D1 = Lambda_mm*0.782 + d1_correction; // Bottom diameter (mm)
D2 = Lambda_mm*2.604 + d2_correction; // Top diameter (mm, D2 > D1)
H = Lambda_mm*0.6;    // Cone height (mm)
t = 2;                // Wall and flange thickness (mm)

gap = 0.1;        // Gap between adjacent trapezoid segments (mm)
eps = 0.05;       // Small overlap for clean CSG boolean operations

// Side Flange Parameters
flange_w = 10;    // Side flange width (mm)
screw_d  = 3.5;   // Side screw hole diameter (mm, for M3)
edge_offset = 28;  // Offset from edges to outer holes (mm)
flange_inset = 1.5; // Radial inset towards Z-axis for full wall intersection (mm)

// Bottom Outer Mount Flange Parameters
bottom_h = 8;            // Height/thickness of the bottom mounting flange (mm)
bottom_flange_w = 20;    // Width of the bottom flange extending outward (mm)
insert_d = 3.7;          // Hole diameter for heat-set insert (mm)

$fn = 32;         // Resolution for cylindrical holes

// =================================================================
// GEOMETRY CALCULATIONS
// =================================================================

ratio = min(1, max_width / D2);
N_calc = ceil(180 / asin(ratio));
N = max(3, N_calc);
step_angle = 360 / N;

echo(str("Calculated number of facets N = ", N));

alpha = atan((D2 - D1) / (2 * H)); // Wall tilt angle relative to vertical
t_rad = t / cos(alpha);            // Radial thickness of the wall

half_angle = step_angle / 2;

// =================================================================
// MODULES
// =================================================================

// Main trapezoidal wall segment of the cone
module main_wall_segment() {
    r1_out = D1 / 2;
    r1_in  = r1_out - t_rad;
    r2_out = D2 / 2;
    r2_in  = r2_out - t_rad;

    // Angular shift to compensate for the gap
    d_ang_1 = (gap / 2) / (r1_out * 180 / PI);
    d_ang_2 = (gap / 2) / (r2_out * 180 / PI);

    a1_R = -half_angle + d_ang_1;
    a1_L =  half_angle - d_ang_1;
    a2_R = -half_angle + d_ang_2;
    a2_L =  half_angle - d_ang_2;

    // Extend the INNER face to match full slant_len (where side_flange ends),
    // keeping the outer face at H so the top cut remains exactly 90 deg to the print bed.
    dh_in = t_rad * sin(alpha) * cos(alpha);
    dr_in = t_rad * pow(sin(alpha), 2);

    z_top_in  = H + dh_in;
    r2_top_in = r2_in + dr_in;

    pts = [
        // Bottom base (z = 0)
        [ r1_out * cos(a1_R), r1_out * sin(a1_R), 0 ], // 0
        [ r1_out * cos(a1_L), r1_out * sin(a1_L), 0 ], // 1
        [ r1_in  * cos(a1_L), r1_in  * sin(a1_L), 0 ], // 2
        [ r1_in  * cos(a1_R), r1_in  * sin(a1_R), 0 ], // 3

        // Top base (Outer at H, Inner extended to match side_flange)
        [ r2_out    * cos(a2_R), r2_out    * sin(a2_R), H ],        // 4: Outer Right
        [ r2_out    * cos(a2_L), r2_out    * sin(a2_L), H ],        // 5: Outer Left
        [ r2_top_in * cos(a2_L), r2_top_in * sin(a2_L), z_top_in ], // 6: Inner Left (Extended)
        [ r2_top_in * cos(a2_R), r2_top_in * sin(a2_R), z_top_in ]  // 7: Inner Right (Extended)
    ];

    faces = [
        [0, 1, 5, 4], // Outer face
        [2, 3, 7, 6], // Inner face
        [0, 4, 7, 3], // Right side cut
        [1, 2, 6, 5], // Left side cut
        [0, 3, 2, 1], // Bottom face
        [4, 5, 6, 7]  // Top face
    ];

    polyhedron(points = pts, faces = faces);
}

// Side mounting flange (ear) with screw holes
module side_flange(side = 1) { // side: 1 - left joint, -1 - right joint
    slant_len = sqrt(pow(H, 2) + pow((D2 - D1) / 2, 2));
    
    holes_z = [
        edge_offset,
        slant_len / 2,
        slant_len - edge_offset
    ];

    intersection() {
        // Crop strictly within Z = [0, H]
        cylinder(r = D2 * 2, h = H, $fn = 4);

        // Align with the joint plane
        rotate([0, 0, side * half_angle]) {
            // Shift towards center by flange_inset to ensure solid intersection
            translate([(D1 / 2) - flange_inset, 0, 0])
                rotate([0, alpha, 0]) {
                    
                    y_trans = (side == 1) ? (-t - gap / 2) : (gap / 2);

                    difference() {
                        // Flange block
                        translate([-eps, y_trans, 0])
                            cube([flange_w + flange_inset + eps, t, slant_len]);

                        // Screw holes
                        for (z_pos = holes_z) {
                            translate([flange_w / 2 + flange_inset, y_trans - eps, z_pos])
                                rotate([-90, 0, 0])
                                    cylinder(d = screw_d, h = t + 2 * eps);
                        }
                    }
                }
        }
    }
}

// Bottom mounting flange extending OUTWARD with heat-set insert hole
module bottom_mount_flange() {
    r1_out = D1 / 2;
    r_ext  = r1_out + bottom_flange_w;
    
    // Position of the insert hole (centered in the outward tab)
    hole_radius = r1_out + (bottom_flange_w / 2);

    // Calculate angular limits matching the bottom gap
    d_ang = (gap / 2) / (r1_out * 180 / PI);
    a_right = -half_angle + d_ang;
    a_left  =  half_angle - d_ang;

    // Radius at height bottom_h along the outer tilted face
    r_outer_at_bottom_h = r1_out + bottom_h * tan(alpha);

    difference() {
        // Outward tab sector starting from the outer wall surface (r1_out - eps)
        polyhedron(
            points = [
                // Inner points embedded slightly into the outer wall surface
                [(r1_out - eps) * cos(a_right), (r1_out - eps) * sin(a_right), 0],
                [(r1_out - eps) * cos(a_left),  (r1_out - eps) * sin(a_left),  0],
                [(r_outer_at_bottom_h - eps) * cos(a_left),  (r_outer_at_bottom_h - eps) * sin(a_left),  bottom_h],
                [(r_outer_at_bottom_h - eps) * cos(a_right), (r_outer_at_bottom_h - eps) * sin(a_right), bottom_h],

                // Outer points (extending outwards)
                [r_ext * cos(a_right), r_ext * sin(a_right), 0],
                [r_ext * cos(a_left),  r_ext * sin(a_left),  0],
                [r_ext * cos(a_left),  r_ext * sin(a_left),  bottom_h],
                [r_ext * cos(a_right), r_ext * sin(a_right), bottom_h]
            ],
            faces = [
                [0, 1, 2, 3], // Inner face (matches outer wall slope)
                [4, 7, 6, 5], // Outer face
                [0, 4, 5, 1], // Bottom face
                [3, 2, 6, 7], // Top face
                [0, 3, 7, 4], // Right side
                [1, 5, 6, 2]  // Left side
            ]
        );

        // Vertical hole for heat-set insert
        translate([hole_radius, 0, -eps])
            cylinder(d = insert_d, h = bottom_h + 2 * eps);
    }
}

// Complete solid segment module
module full_trapezoid_segment() {
    union() {
        main_wall_segment();
        side_flange(side = 1);  // Left side flange
        side_flange(side = -1); // Right side flange
        bottom_mount_flange();  // Bottom outer flange with heat-set insert hole
    }
}

module holes_template() {
    difference() {
        cylinder(h = t, d = D1 + 2*bottom_flange_w, center = true, $fn = 100);
        cylinder(h = t*2, d = D1, center = true, $fn = 100);

        for (i = [0 : N - 1]) {
            rotate([0, 0, i * step_angle]) {
                r1_out = D1 / 2;
                r_ext  = r1_out + bottom_flange_w;
                hole_radius = r1_out + (bottom_flange_w / 2);
                
                translate([hole_radius, 0, -t/2-eps])
                    cylinder(d = insert_d, h = bottom_h + 2 * eps);
            }
        }
    }
}

// =================================================================
// RENDER / ASSEMBLY
// =================================================================

// Preview entire assembly:
for (i = [0 : N - 1]) {
    rotate([0, 0, i * step_angle])
        full_trapezoid_segment();
}

translate([0, 0, -20])
    holes_template();

// #cylinder(d = D1 - d1_correction, h = 200, center = true);

// the reference ideal cone without corrections
/*
#difference() {
    cylinder(d1 = D1-d1_correction+2*t, d2 = D2-d2_correction+2*t, h = H);
    translate([0,0,-eps/2])
        cylinder(d1 = D1-d1_correction, d2 = D2-d2_correction, h = H+eps);
}
*/

// 3D-printable parts:
//
// full_trapezoid_segment();
// holes_template();

