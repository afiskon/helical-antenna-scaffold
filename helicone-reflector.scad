// see http://home.etf.rs/~milanilic/publications/papers/Djordjevic-Etran06.pdf

F_MHz = 2450;
Lambda_mm = (299792458 / (F_MHz*1000000))*1000;

D1 = 0.782 * Lambda_mm;
D2 = 2.604 * Lambda_mm;
H = 0.6 * Lambda_mm;
t = 5;

base_t = 6;
base_extra_d = 50;
base_hole_d = 3.7;
base_hole_off = 10;

show_cone = true;

eps = 0.01;
$fn = 100;

difference() {
    union() {
        if(show_cone)
            cylinder(d1 = D1+2*t, d2 = D2+2*t, h = H, center = true);
            
        translate([0, 0, -H/2+base_t/2])
            difference() {
                cylinder(d = D1 + base_extra_d, h = base_t, center = true);
                
                for(angle = [0, 120, 240])
                    rotate([0, 0, angle])
                        translate([(D1+base_extra_d)/2-base_hole_off,0,0])
                            cylinder(d = base_hole_d, h = base_t+eps, center = true);
            }
    }
    cylinder(d1 = D1, d2 = D2, h = H+eps, center = true);
}