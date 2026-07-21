$fn = 100;
eps = 0.01;

show_base = true;
show_base_clamp = true;
show_cover = true;
show_cutting_template = true;

base_clamp_screw_offset = 8;

typen_center = 18.2;
typen_screw_hole = 3.7;
typen_screw_hole_offset = 18/2;
typen_height = 10;
typen_deepening = 2.5;

lnb_mount_d = 60;
lnb_mount_t = 3;
lnb_mount_angle_size = 4;
lnb_mount_h = 24; /* including lnb_mount_angle_size! */

mount_cutoff_angle = 45;

base_dia = 112;
base_t = 6;
base_hole_dia = 54;

mounting_holes_dia = 7;
mounting_separation = 80;

side_hole_d = 4;
side_hole_t = 7;

cover_t = 1.5;
cover_sp = 0.2;
cover_h = 145;
cover_top_dia = 65;

module typen_holes() {
    cylinder(d = typen_center, h = typen_height, center = true);
    translate([typen_screw_hole_offset, typen_screw_hole_offset, 0])
        cylinder(d = typen_screw_hole, h = typen_height, center = true);
    translate([typen_screw_hole_offset, -typen_screw_hole_offset, 0])
        cylinder(d = typen_screw_hole, h = typen_height, center = true);
    translate([-typen_screw_hole_offset, typen_screw_hole_offset, 0])
        cylinder(d = typen_screw_hole, h = typen_height, center = true);
    translate([-typen_screw_hole_offset, -typen_screw_hole_offset, 0])
        cylinder(d = typen_screw_hole, h = typen_height, center = true);
}

module mount_base(right = false, left = false) {
    rotate([0, 180, 0]) intersection() {

        union() {
            if(right)
                translate([0, 100/2, 0])
                    cube([100, 100, lnb_mount_h+eps], center = true);
            
            if(left)
                translate([0, -100/2, 0])
                    cube([100, 100, lnb_mount_h+eps], center = true);
        }
    
        difference() {
            union() {
                difference() {
                    union() {
                        cylinder(d = lnb_mount_d + 2*lnb_mount_t, h = lnb_mount_h, center = true);
                        
                        cube([lnb_mount_d + 2*lnb_mount_t + 15*2, 2*lnb_mount_t+1, lnb_mount_h], center = true);
                    }
                    cylinder(d = lnb_mount_d, h = lnb_mount_h+eps, center = true);

                    
                    translate([lnb_mount_d/2+lnb_mount_t+15/2, 0, 0]) rotate([90, 0, 0])
                        cylinder(h = 100, d = 3.5, center = true);
                    translate([-lnb_mount_d/2-lnb_mount_t-15/2, 0, 0]) rotate([90, 0, 0])
                        cylinder(h = 100, d = 3.5, center = true);
                }
        
                translate([0,0, lnb_mount_h/2-lnb_mount_angle_size/2]) difference() {
                    cylinder(d = lnb_mount_d + eps, h = lnb_mount_angle_size, center = true);
                    cylinder(d1 = lnb_mount_d + eps, d2 = lnb_mount_d - 2*lnb_mount_angle_size, h = lnb_mount_angle_size+eps, center = true);
                }
    
            }
            
            cube([lnb_mount_d + 2*lnb_mount_t + 15*2+eps, 1, lnb_mount_h+eps], center = true);
        }
    }
}

/* COVER */
if(show_cover) {
    union() {
        translate([0, 0, base_t/2]) difference() {
            cylinder(d = base_dia+2*cover_t+2*cover_sp, h = base_t, center = true);
            cylinder(d = base_dia+2*cover_sp, h = base_t+eps, center = true);
            
            for(i = [0:2])
                rotate([0, 0, 120*i])
                    translate([0, base_dia/2+eps, 0])
                        rotate([90, 0, 0])
                            translate([0, 0, -side_hole_t/2])
                                cylinder(d = 3.5, h = side_hole_t);
        }
        
        translate([0, 0, (cover_h+cover_t)/2+base_t-eps]) difference() {
            cylinder(h = cover_h+cover_t, d1 = base_dia+2*cover_t+2*cover_sp, d2 = cover_top_dia+2*cover_t, center = true);
            
            translate([0, 0, -cover_t/2-eps]) cylinder(h = cover_h, d1 = base_dia-2, d2 = cover_top_dia, center = true);
        }
    }
}

/* BASE */
if(show_base) {
    union() {
        translate([0, 0, base_t/2-eps]) difference() {
            cylinder(d = base_dia, h = base_t, center = true);
            cylinder(d = base_hole_dia, h = base_t+eps, center = true);
            
            translate([0, -lnb_mount_d/2-lnb_mount_t-7, 0])
                union() {
                    typen_holes();
                    
                    /* A deepening for type-N connector */
                    translate([0, 0, lnb_mount_t-typen_deepening/2+eps])
                        cube([25.5, 25.5, typen_deepening], center = true);
                }
            translate([mounting_separation/2, 0, 0])
                cylinder(d = mounting_holes_dia, h = 100, center = true);
            translate([-mounting_separation/2, 0, 0])
                cylinder(d = mounting_holes_dia, h = 100, center = true);
            
            rotate([0, 0, 45]) translate([0, lnb_mount_d/2+base_clamp_screw_offset, 0])    
                cylinder(d = 3.5, h = base_t+eps, center = true);
            
            for(i = [0:2])
                rotate([0, 0, 120*i])
                    translate([0, base_dia/2-side_hole_t/2+eps, 0])
                        rotate([90, 0, 0])
                            translate([0, 0, -side_hole_t/2])
                                cylinder(d = side_hole_d, h = side_hole_t);
        }
        
        translate([0, 0, -lnb_mount_h/2+eps]) difference() {
            rotate([0, 0, 45]) mount_base(left = true);
            
            rotate([0, 0, -mount_cutoff_angle/2-90]) translate([0, 0, -lnb_mount_h/2-eps/2])
                rotate_extrude(angle = mount_cutoff_angle)
                    polygon([[0, 0], [0, lnb_mount_h+eps], [100, lnb_mount_h+eps], [100, 0]]);
        }
    }
}

/* CUTTING TEMPLATE */
if(show_cutting_template) {
    translate([0, 0, -30]) difference() {
        cylinder(d = base_dia-3, h = base_t/2, center = true);
        cylinder(d = base_hole_dia+2, h = base_t/2+eps, center = true);
        
        translate([0, -lnb_mount_d/2-lnb_mount_t-7, 0])
            typen_holes();
        translate([mounting_separation/2, 0, 0])
            cylinder(d = mounting_holes_dia, h = 100, center = true);
        translate([-mounting_separation/2, 0, 0])
            cylinder(d = mounting_holes_dia, h = 100, center = true);
        
        rotate([0, 0, 45]) translate([0, lnb_mount_d/2+base_clamp_screw_offset, 0])    
            cylinder(d = 3.5, h = base_t+eps, center = true);
    }
} 

/* BASE CLAMP */
if(show_base_clamp) {
    translate([0, 0, -lnb_mount_h/2+eps])
        rotate([0, 0, 45])
            difference() {
                union() {
                    mount_base(right = true);
                    
                    translate([0, lnb_mount_d/2+base_clamp_screw_offset, 0])
                        cylinder(d = 10, h = lnb_mount_h, center = true);
                   
                    /* some hackery here... */
                    translate([0, lnb_mount_d/2+5, 0])
                        cube([10, 6, lnb_mount_h], center = true);
                }
                
                translate([0, lnb_mount_d/2+base_clamp_screw_offset, lnb_mount_h/2])
                    cylinder(d = 4, h = lnb_mount_h, center = true);
            }
}