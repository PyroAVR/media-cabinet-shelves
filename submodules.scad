/**
 * Centers a bounding box along its dimension in each axis specified as "true"
 */
function autocenter(dims, center_x, center_y, center_z) =
    let(shifts = -dims / 2)
        [
            center_x ? shifts[0]:0,
            center_y ? shifts[1]:0,
            center_z ? shifts[2]:0,
        ];

module array_children(spacing, count, along=[1, 0, 0]) {
    for(i = [0: count-1]) {
        translate(spacing*i*along) children();
    }
}

/**
 * Draws a bounding box, optionally centered along its dimension in each
 * axis. Intended use is for drawing I/O ports for common connectors.
 */
module port(dims, center_x=true, center_y=true, center_z=false) {
    translate(autocenter(dims, center_x, center_y, center_z)) cube(dims);
}

/**
 * Transform something like OpenSCAD's cube() (growing away from origin in only
 * positive magnitude in every dimension) to have the origin of its bounding
 * box at its upper-left corner, given the dimensions of the bounding box.
 */
module origin_at_front_left_upper(dims) {
    translate([0, -dims.y, -dims.z]) children();
}

module origin_at_front_right_upper(dims) {
    translate([0, 0, -dims.z]) children();
}

module origin_at_rear_left_lower(dims) {
    translate([-dims.x, 0, 0]) children();
}

/**
 * Sample a function along a range. The range specified is [start, stop, step],
 * like Python.
 */
sample = function(fn, range) [for(i=[range[0]:range[2]:range[1]]) fn(i)];
xysample = function(fn, range) [for(i=[range[0]:range[2]:range[1]]) [i, fn(i)]];
yxsample = function(fn, range) [for(i=[range[0]:range[2]:range[1]]) [fn(i), i]];

/**
 * Create a polygon that is axis-up-to-curve, with curve defined by func.
 * range is like python range: [start, stop, step], step is optional and
 * defaults to 1.
 * If reflectorigin is set, the independent variable is swept along the y axis,
 * instead of x.
 * If parametric is set, then func must return [x, y] pairs instead of only the
 * dependent variable value for a given independent variable.
 */
module curve_bounded_solid(func, range, reflectorigin=false, parametric=false) {
    start = range[0];
    stop = range[1];
    step = len(range) > 2 ? range[2]:1;
    sampler = reflectorigin ? yxsample: (parametric ? sample:xysample);
    curve_points = sampler(func, [start, stop, step]);
    points = concat([[curve_points[0].x, 0]],
        curve_points, [[curve_points[len(curve_points)-1].x, 0]]);
    polygon(points = points);
}

/**
 * Quadratic bezier curve function, with p0 as start, p1 as "control", and p2 as
 * stop point.
 */
function qbez(p0, p1, p2, t) = pow(1-t, 2)*p0 + 2*(1-t)*t*p1 + pow(t, 2)*p2;

/**
 * Recursive bezier curve function:
 * let B0(t; P0) = P0, then
 * Bn(t) = (1-t)B(t;[P0,Pn-1]) + t*B(t; [P1, Pn])
 * https://en.wikipedia.org/wiki/B%C3%A9zier_curve
 *
 * control_points is a list of X, Y coordinates: [[x1, y1], ... , [xn, yn]]
 * t is the point to evaluate.
 */
function rbez(control_points, t) = let(n = len(control_points))
    n == 1 ? control_points[0]:
        ((1-t)*rbez([for(i = [0:1:n-2]) control_points[i]], t)) +
        (t*rbez([for(i = [1:1:n-1]) control_points[i]], t));

/**
 * A box with rounded edges and exactly the specified dimensions in each plane
 * projection.
 */
module beam(dimensions, rounded=0.5, center_x = true, center_y = true, center_z = false, $fn=20) {
    shifts = -dimensions / 2;
    translate_dims = [
        center_x ? shifts[0]:0,
        center_y ? shifts[1]:0,
        center_z ? shifts[2]:0,
    ];
    translate(translate_dims + [rounded, rounded, rounded])
    minkowski() {
        cube(dimensions - rounded*[2, 2, 2]);
        sphere(r=rounded);
    }
}

/**
 * Makes a slice of a pie with the specified radius and circumferential span
 */
module pie_slice(r, degrees) {
    center = [0, 0];
    outer = [for(i = [0:degrees/$fn:degrees]) [r*cos(i), r*sin(i)]];
    rotate([0, 0, -degrees/2]) polygon(concat([center], outer, [center]));
}

/**
 * Join two faces at an angle, filling in the gap resulting from the angle
 * and any spacing between the two faces. The faces need to have the edges
 * to be joined on the xy plane, centered on the origin. Eg. if the faces have
 * thickness 3, the two faces should have a midpoint of [0, 0, 1.5].
 *
 * The joiner module
 * Use like:
 *     face_join(pie_slice, 3, 30, 10, 0) {
 *         object1_on_xy_plane();
 *         rotate([0, 30, 0]) object2_on_xy_plane();
 *     }
 */
module face_join(joiner="pie", thickness, degrees, depth, separation=0) {
    rotate([-degrees/2, 0, 0]) children(0);
    rotate([degrees/2, 0, 0]) children(1);
    rotate([0, -90, 0])
    if(joiner == "pie") {
        linear_extrude(depth) pie_slice(thickness, degrees);
    }
    else {
        echo(str("ERROR: joiner \"", joiner, "\" is not supported."));
    }
}
