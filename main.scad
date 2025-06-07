use <submodules.scad>
use <../dovetail/main.scad>

/**
 * For use with "port" module
 */
dc_jack_dims = [14, 9, 11];
ethernet_dims = [22, 16, 14];

/**
 * Draws a bounding box for the netgear 5-port POE switch, with locations for
 * the ethernet and DC barrel jacks
 */
gs305epp_dims = [158.75, 101, 26];
module netgear_gs305epp(center_x=true, center_y=true, center_z=false) {
    translate(autocenter(gs305epp_dims, center_x, center_y, center_z)) {
        // from origin x, top z
        jack_offset = [20.5, 0, -18];
        ethernet_hub_offset = [46, 0, -7];
        // from positive x, top z
        ethernet_trunk_offset = [-23.5, 0, -7];
        left_rear_top = [0, gs305epp_dims.y, gs305epp_dims.z];
        left_front_top = [0, 0, gs305epp_dims.z];
        right_front_top = [gs305epp_dims.x, 0, gs305epp_dims.z];

        color("#4f4f4f") port(gs305epp_dims, false, false, false);
        // power jack
        color("white") translate(left_rear_top + jack_offset) rotate([0, 0, 90])
            origin_at_rear_left_lower(dc_jack_dims)
                port(dc_jack_dims, false, false, false);

        // switched ports
        color("white") translate(left_front_top + ethernet_hub_offset)
            array_children(ethernet_dims.y, 4)
                rotate([0, 0, 90]) origin_at_front_left_upper(ethernet_dims)
                    port(ethernet_dims, false, false, false);

        // trunk port
        color("white") translate(right_front_top + ethernet_trunk_offset)
            rotate([0, 0, 90]) origin_at_front_right_upper(ethernet_dims)
                port(ethernet_dims, false, false, false);
    }
}

/**
 * With CanaKit fan case
 */
raspberrypi5_dims = [94, 63, 33];
module raspberrypi5(center_x=true, center_y=true, center_z=true) {
    translate(autocenter(raspberrypi5_dims, center_x, center_y, center_z)) {
        // disable beam autocentering
        beam(raspberrypi5_dims, rounded=5.0, false, false, $fn=30);
    }
}

// these modules from: https://www.printables.com/model/302365-leviton-structured-media-extended-shelf-and-bracke
module left_bracket_orig() {
    translate([-244.75, 0, 3]) rotate([0.9986, 90, 0]) import("bracket_lft_v2.stl");
}
module right_bracket() {
    translate([0.20, -4.25, 3]) rotate([0, 90, 0.9986]) import("bracket_rht_v2.stl");
}

module shelf_brackets(units=1) {
    dims = [units * (72.5 + 5.5), -12.0, 0]; // y, z ignored
    // brackets are backwards... invert dims to fix
    translate(autocenter(-dims, true, true, false)) {
        rotate([90, 0, -90]) bracket(3, false);
        // translated 2x peg widths + 2x bracket width
        translate([-dims.x + 3.0, 0, 0]) rotate([90, 0, -90]) bracket(3, true);
    }
}

module measuring_stick() {
    // spacing for the cabinet is 72.5 mm on center of each hole
    // the holes themselves are 5mm in diameter.
    color("red") translate([0, -15, -50.5]) cube([72.5, 1, 1]);
    color("blue") translate([-72.5, -15, -50.5]) cube([72.5, 1, 1]);
}

/**
 * The hull of two circles, or, a drawing of a powder-filled pill from above
 * dims: [width, radius, depth]
 */
module pill2d(dims) {
    linear_extrude(dims.z) hull()
        array_children(dims.x - 2*dims.y, 2) circle(r=dims.y);
}

module shelf(units=1) {
    // 75 instead of 72.5 because the dovetails are slightly wider than the
    // bracket center spacing
    dims = [75 * units, 60, 3.75];
    offsets = [0, 16, 0];
    module dovetail_slot() {
        difference() {
            cube([5, dims.y, 3.5]);
            // all these ridiculous shifts and dilations are from trying to make
            // things line up in the orthogonal projection view
            color("white")translate([3.25, 16.955, 0])
            union() array_children(8.03 + 21.35, 2, along=[0, 1, 0]) {
               linear_extrude(5) dovetail_profile(
                   [8.03, 4.00599, 3.5], slot=true, dtype="cart", eps=0.04);
            }
        }
    }
    translate(autocenter(dims, true, false, false)) {
        translate([5, offsets.y, 0]) rotate([0, 180, 0]) dovetail_slot();
        translate([dims.x-5, offsets.y, -3.5]) dovetail_slot();
        translate([0, offsets.y, 0]) difference() {
            cube(dims);
            // slot for power cable to hang through
            translate([20, 20, -1]) rotate([0, 0, 90]) pill2d([50, 6, 5]);

            // general slots for... air? aesthetic? less plastic?
            // also fitting zip-ties through
            translate([40, 10, -1]) array_children(6, 18)
                rotate([0, 0, 90]) pill2d([20, 1.5, 5]);
            translate([40, 35, -1]) array_children(6, 18)
                rotate([0, 0, 90]) pill2d([20, 1.5, 5]);
        }
    }
}

/**
 * 3mm tall dovetails to interlock the shelf and the brackets.
 * Spacing is 33% and 66% of the total shelf depth: 20 and 40 mm.
 */
module dovetail_interlock(slot=false) {
    dims = [60, 3.75];
    module array() {
        difference() {
            cube([5, dims.y, 5]);
            // all these ridiculous shifts and dilations are from trying to make
            // things line up in the orthogonal projection view
            color("white")translate([3.25, 16.955, 0])
            union() array_children(8.03 + 21.35, 2, along=[0, 1, 0]) {
               linear_extrude(5) dovetail_profile(
                   [8.03, 4.00599, 3.5], slot=true, dtype="cart", eps=0.04);
            }
        }
    }
    if(slot) {
        difference() {
            cube([5, dims.y, 5]);
        }
    }
}

// measured from print
module bracket(thickness=3, flip=false, compat=true) {
    // taken from measurement in OpenSCAD
    top_surface_depth = 8.5663;
    curve_dims = [82.1618, -45.8769 -16.04, thickness];

    // Tilt the strut inwards so that it will pinch the cabinet when in place.
    // A large enough tilt will require filler material
    tilt_angle = -3;

    // dovetails for attaching the shelf
    dovetail_dims = compat ? [8.03, 4.00599, 3.5]: [8, 4, 3.5];
    spacing = compat ? 8.03 + 21.35: 30;


    // main assembly
    rotate([(flip? -1:1) * tilt_angle/2, 0, 0])
    face_join("pie", 3, (flip? 1:-1) * tilt_angle, curve_dims.x) {
        // lower bracket
        union() {
            translate([-curve_dims.x, curve_dims.y, 0])
                linear_extrude(thickness)
                    import("lower-curve.svg");
            // TODO 41.75 is not quite right... need to measure how far off I am
            translate([-0.15, -41.75, flip? 0.25:thickness-0.25])
                rotate([90, (flip ? 180:0), 90]) cabinet_peg(fraction=1/2.2);

        }
        // latching tab & shelf mount surface
        union() {
            translate([-curve_dims.x, 0, 0])
                cube([curve_dims.x, top_surface_depth, thickness]);
            dovetail_shift = [
                compat ? -39.0 : -35, // Leviton spacing: my spacing
                (flip ? 0.0:-3.0) + top_surface_depth,
                flip? -dovetail_dims.z/2:(thickness + dovetail_dims.z/2)];
            translate(dovetail_shift)
            array_children(spacing, 2, along=[-1, 0, 0]) {
                rotate([0, (flip ? -1:1) * 90, 90]) linear_extrude(3) dovetail_profile(
                    dovetail_dims, slot=false, dtype="cart", eps=0.00);
            }
            translate([0, top_surface_depth + 0.5, flip? thickness:20]) rotate([-90, 90, 0]) {
                translate([flip? 0:(20 - thickness), 0, -0.5]) cube([thickness, 22, 0.5]);
                // somehow I lost the little 0.5mm tall spacer that goes here.
                shelf_tab_latch(flip);
                // place upper shelf pin
                translate([(flip? 2:20-2), 0, thickness-1.3]) rotate([-90, 0, 180])
                    cabinet_hook(4, 3, rounded=1.5, hook_shaft_h=6, hook_shaft_flat_frac=1.4);
            }
        }
    }
}

/**
 * A latching peg which fits into the columns of holes inside the cabinet.
 * I measured 5mm ID on my cabinet from Primex, so this is slightly smaller to
 * easily slip inside. When mounting, ensure that the attached structure applies
 * pressure towards the center of the peg along the Y dimension so that the
 * latching mechanism will work as intended.
 */
module cabinet_peg(thickness=3.2, d=5.5, fraction=1/3) {
    difference() {
        union() {
            intersection() {
                cylinder(d=d, h=thickness);
                translate([0, -d*fraction, 0]) cylinder(d=d, h=thickness);
            }
            translate([0, 0, thickness]) cylinder(d=d, h=thickness);
        }
        translate([0, thickness, 2*thickness + 3]) rotate([70, 0, 0]) cube([10, 10, 10], center=true);
    }
}

/**
 * Create a horizontal shelf with tabs to mount a larger shelf. Also create a
 * vertical, downward-extending tab which applies pressure against the rear of
 * the cabinet to engage the locking mechanism.
 */
module shelf_tab_latch(flip=false, rounded=0.5) {
    // top surface
    cube([20, 22, 3]);

    // pressure tab
    ptab_translate_dims = [flip ? 11 - 2*rounded:0, 0, 0];
    translate(ptab_translate_dims) rotate([-100, 0, 0]) linear_extrude(2) {
        // slightly lengthened (-1 y) so that the final shape is a convex solid
        tl = [0, -1];
        tr = [9, -1];
        bl = [1, 20];
        br = [8, 20];
        translate(rounded * [1, 1, 1]) minkowski() {
            polygon(points=[tl, tr, br, bl]);
            circle(r=rounded);
        }
    }

    // larger shelf support tab
    rotate_amt = [0, 180, 0];
    stab_translate_dims = flip ? [20, 16, 0]:[12, 16, 0];
    //rotate_amt = [0, 0, 0];
    //stab_translate_dims = [0, 0, 0];
    translate(stab_translate_dims) rotate(rotate_amt) hull() {
        // base surface
        let(
            bl = [0, 0],
            tl = flip ? [0, 8]:[4.5, 8],
            br = [12, 0],
            tr = flip ? [12 - 4.5, 8]:[12, 8])
        linear_extrude(0.01) polygon(points=[tl, tr, br, bl]);
        // top surface
        let(
            bl = flip ? [0, 3]:[1.8, 3],
            tl = flip ? [0, 8]:[4.5, 8],
            br = flip ? [12 - 1.8, 3]:[12, 3],
            tr = flip ? [12 - 4.5, 8]:[12, 8])
        translate([0, 0, 2.99]) linear_extrude(0.01) polygon(points=[tl, tr, br, bl]);
    }
}

/**
 * A hook which pulls against the hidden face of the rear panel of the cabinet.
 * Leviton cabinets appear to have a material thickness around 3.5mm, but that
 * did not fit in my Primex cabinet when I tried it (at least not well).
 * Assuming 4mm.
 */
module cabinet_hook(hole_size=5, material_thickness=4, eps=0.1, rounded=0, hook_shaft_r=2.5, hook_shaft_h=4, hook_shaft_flat_frac=1.5, main_shaft_flat_frac=0.66) {
    // holes are ~5mm ID, so the hook needs to be a bit smaller.
    // diam, length
    hook_shaft = [hook_shaft_r, hook_shaft_h];
    main_shaft = [hole_size - eps, material_thickness];
    difference() {
        // primary shape
        hull() {
            cylinder(d=main_shaft.x, h=main_shaft.y);
            translate([0, 0, material_thickness]) rotate([90, 0, 0]) cylinder(d=hook_shaft.x, h=hook_shaft.y);
            translate([0, 0, material_thickness]) sphere(d=main_shaft.x);
        }

        rounding_radius = ((material_thickness > 1) && (rounded == 0)) ? 1:rounded == 0 ? material_thickness/2:rounded;
        // flat inner surface to press against rear face of the cabinet back panel
        translate([0, -(hook_shaft.y + material_thickness + main_shaft_flat_frac*main_shaft.x), -main_shaft.y/2])
        beam(main_shaft.y*[5, 0, hook_shaft_flat_frac] + [0, hook_shaft.y + material_thickness + main_shaft.x/2, 0], rounded=rounding_radius, true, false, false, $fn=$fn);
    }

}
$fn = 60;
color("gray") shelf_brackets(2);
color("gray") translate([0, 0, 9.15]) shelf(2);
//measuring_stick();

// hangs off the edge a bit to allow more room for the dc jack at the bottom
// translate([8.5, 60, gs305epp_dims.y/2 + 13]) rotate([-90, 0, 0]) netgear_gs305epp(true, true, true);
