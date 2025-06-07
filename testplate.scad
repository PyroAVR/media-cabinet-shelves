use <submodules.scad>;
module primex_plate(thickness, vspacing=25, id=6, hspacing=72.5, pad=5) {
    linear_extrude(thickness) difference() {
        translate([pad, pad, 0]) minkowski() {
            circle(r=pad);
            square([vspacing, hspacing]);
        }
        translate([pad, pad, 0]) array_children(vspacing, 2, [1, 0])
            array_children(hspacing, 2, [0, 1])
                translate([0, 0, -0.1]) circle(r=id/2);
        translate([pad + id, pad + id]) minkowski() {
            circle(r=3);
            square([(vspacing-2*id), (hspacing-2*id)]);
        }
    }
}

$fn=50;
primex_plate(3, vspacing=50);
translate([75, 0, 0]) primex_plate(4, vspacing=50);
