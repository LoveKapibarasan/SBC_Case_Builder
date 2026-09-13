/*
    This file is part of SBC Case Builder https://github.com/hominoids/SBC_Case_Builder

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>
    Code released under GPLv3: http://www.gnu.org/licenses/gpl.html


           NAME: split_part
    DESCRIPTION: splits the top or bottom of a shell case into as many tiles as it
                 takes to fit a print bed. every cut gets a flange on each side, standing up from
                 the floor and running up the walls, and the two flanges are bolted
                 back to back with M3. cut positions are chosen automatically to
                 keep clear of the sbc mounting holes and of the keepout ranges.
           TODO: panel, tray and other case designs

          USAGE: split_part() children();

                 children = the individual part exactly as rendered by view "part"

*/


// sbc mounting hole centres in case coordinates
function split_pcb_holes() =
    [for(i = [1:11:len(sbc_data[s[0]])-2])
        if(sbc_data[s[0]][i+1] == "pcbhole" && sbc_data[s[0]][i+3] == pcb_id)
            [sbc_data[s[0]][i+4] + pcb_loc_x, sbc_data[s[0]][i+5] + pcb_loc_y]];

// outer extent of the part along x and y in part view coordinates
function split_x0() = -wallthick - gap;
function split_y0() = individual_part == "top" ? wallthick + gap : -wallthick - gap;
function split_height() = individual_part == "top" ? top_height : bottom_height;

// hole positions along one axis in part view coordinates, the top is mirrored in y
function split_hole_axis(axis) =
    [for(h = split_pcb_holes())
        axis == 0 ? h[0] : individual_part == "top" ? depth - h[1] : h[1]];

// number of tiles along an axis so that every tile fits the usable bed
function split_count(ln, bed) = max(1, ceil(ln / (bed - split_bed_margin)));

// clearance of a candidate cut from every mounting hole
function split_clear(c, holes) = len(holes) == 0 ? 1000 : min([for(h = holes) abs(h - c)]);

// keepout ranges [min, max] in case coordinates, converted to part view along the axis
function split_keepouts(axis) =
    axis == 0 ? split_keepout_x :
    individual_part == "top" ? [for(k = split_keepout_y) [depth - k[1], depth - k[0]]] : split_keepout_y;

// a cut is allowed when it keeps clear of holes and of every keepout range
function split_ok(c, holes, keeps) =
    (len(holes) == 0 || split_clear(c, holes) >= split_hole_clear) &&
    len([for(k = keeps) if(c > k[0] - split_flange_t - 2 && c < k[1] + split_flange_t + 2) 1]) == 0;

/* cut positions along one axis, in part view coordinates. with n tiles the k-th
   cut starts at the equal division and walks outward to the first position that
   keeps clear of holes and keepouts while the tile behind it and all the tiles
   still to come fit the bed. a manual split_x / split_y is used for a two tile
   split */
function split_cuts(axis) =
    let(o = axis == 0 ? split_x0() : split_y0(),
        ln = axis == 0 ? width : depth,
        bed = (axis == 0 ? split_bed_x : split_bed_y) - split_bed_margin,
        n = split_count(ln, axis == 0 ? split_bed_x : split_bed_y),
        manual = axis == 0 ? split_x : split_y)
    n < 2 ? [] :
    (n == 2 && manual > 0) ? [o + manual] :
    split_cuts_rec(o, ln, bed, n, 1, o, split_hole_axis(axis), split_keepouts(axis), []);

function split_cuts_rec(o, ln, bed, n, k, prev, holes, keeps, acc) =
    k >= n ? acc :
    let(target = o + ln*k/n,
        cands = [for(d = [0:1:bed/2]) for(c = [target - d, target + d])
                    if(c - prev <= bed && c - prev > 0 && (o + ln) - c <= bed*(n - k) &&
                       split_ok(c, holes, keeps)) c],
        c = len(cands) > 0 ? cands[0] : target)
    split_cuts_rec(o, ln, bed, n, k + 1, c, holes, keeps, concat(acc, [c]));


/* floor flange cross section for a cut normal to axis, as a 2D shape in the plane
   of the cut. u runs along the cut, v is height */

module split_floor_flange_2d(axis) {

    u0 = axis == 0 ? split_y0() + wallthick : split_x0() + wallthick;
    u1 = axis == 0 ? split_y0() + depth - wallthick : split_x0() + width - wallthick;
    translate([u0, 0]) square([u1 - u0, floorthick + split_flange_h]);
}


/* bolt positions in a flange, [u, v] in the plane of the cut */

function split_bolts(axis, other_cuts) =
    let(h = split_height(),
        u0 = (axis == 0 ? split_y0() : split_x0()) + wallthick,
        u1 = (axis == 0 ? split_y0() + depth : split_x0() + width) - wallthick,
        fh = split_flange_h,
        vf = floorthick + fh/2,
        n = max(2, floor((u1 - u0 - 2*fh) / split_bolt_spacing) + 1),
        floor_bolts = [for(k = [0:n-1])
            let(u = u0 + fh + split_bolt_edge + k*(u1 - u0 - 2*fh - 2*split_bolt_edge)/(n-1))
                if(len([for(oc = other_cuts) if(abs(u - oc) <= split_flange_t + 4) 1]) == 0) [u, vf]],
        // at least one bolt up each wall once the wall is tall enough to take it
        wall_free = h - floorthick - fh - split_bolt_edge,
        nv = wall_free < 2*split_bolt_edge ? 0 : max(1, floor(wall_free / split_bolt_spacing)),
        wall_bolts = nv < 1 ? [] :
            [for(k = [1:nv]) for(u = [u0 + fh/2, u1 - fh/2])
                [u, floorthick + fh + k*(h - floorthick - fh)/(nv+1)]])
    concat(floor_bolts, wall_bolts);


/* flange solid on one side of the cut. side is -1 for the low tile, +1 for the high.

   the floor flange is a plain strip. the wall flange is the wall material actually
   present at the cut, thickened by split_flange_h perpendicular to the wall, so it
   follows openings such as the rear I/O aperture or expansion slots instead of
   blocking them. children() is the unsplit part */

module split_flange(axis, cut, side) {

    t = split_flange_t;
    big = 1000;
    fh = split_flange_h;
    lo = side < 0 ? cut - t : cut;
    // outer extent of the part, the grown wall is trimmed back to it
    ox = split_x0();
    oy = split_y0();

    if(axis == 0) {
        translate([lo, 0, 0]) rotate([90, 0, 90]) linear_extrude(height = t) split_floor_flange_2d(0);
        intersection() {
            translate([ox, oy, 0]) cube([width, depth, split_height()]);
            minkowski() {
                intersection() {
                    children();
                    translate([lo, -big/2, floorthick + .01]) cube([t, big, big]);
                }
                translate([0, -fh, 0]) cube([.01, 2*fh, .01]);
            }
        }
    }
    else {
        translate([0, lo + t, 0]) rotate([90, 0, 0]) linear_extrude(height = t) split_floor_flange_2d(1);
        intersection() {
            translate([ox, oy, 0]) cube([width, depth, split_height()]);
            minkowski() {
                intersection() {
                    children();
                    translate([-big/2, lo, floorthick + .01]) cube([big, t, big]);
                }
                translate([-fh, 0, 0]) cube([2*fh, .01, .01]);
            }
        }
    }
}


module split_bolt_holes(axis, cut, other_cuts) {

    t = split_flange_t;
    for(b = split_bolts(axis, other_cuts)) {
        if(axis == 0) {
            translate([cut - t - 1, b[0], b[1]]) rotate([0, 90, 0]) cylinder(d=split_bolt_dia, h=2*t + 2, $fn=24);
        }
        else {
            translate([b[0], cut - t - 1, b[1]]) rotate([-90, 0, 0]) cylinder(d=split_bolt_dia, h=2*t + 2, $fn=24);
        }
    }
}


module split_part() {

    x0 = split_x0();
    y0 = split_y0();
    cx = split_cuts(0);
    cy = split_cuts(1);
    big = 1000;
    xs = concat([x0 - big], cx, [x0 + width + big]);
    ys = concat([y0 - big], cy, [y0 + depth + big]);

    echo(split_tiles = str(len(xs) - 1, " x ", len(ys) - 1),
         split_cuts_x = [for(c = cx) c - x0], split_cuts_y = [for(c = cy) c - y0]);
    echo(split_cut_x_hole_clearance = [for(c = cx) split_clear(c, split_hole_axis(0))],
         split_cut_y_hole_clearance = [for(c = cy) split_clear(c, split_hole_axis(1))]);

    // joint test coupon: both sides of the first cut, clipped to a small block that
    // takes in the floor, the wall at the part edge and the wall flange, for a test print
    if(split_tile == "test") {
        axis = len(cx) > 0 ? 0 : 1;
        c = len(cx) > 0 ? cx[0] : len(cy) > 0 ? cy[0] : undef;
        if(c == undef) echo("split_part: no cut, nothing to test");
        else {
            half = split_test_size[0]/2;
            reach = split_test_size[1];
            tall = min(split_height(), split_test_size[2]);
            echo(split_test_coupon = str(axis == 0 ? "x" : "y", " cut at ", c - (axis == 0 ? x0 : y0),
                 ", block ", 2*half, " x ", reach, " x ", tall));
            for(side = [-1, 1]) {
                lo = side < 0 ? c - half : c;
                translate(axis == 0 ? [side*split_explode/2, 0, 0] : [0, side*split_explode/2, 0])
                difference() {
                    intersection() {
                        union() {
                            children();
                            split_flange(axis, c, side) children();
                        }
                        if(axis == 0) translate([lo, y0 - 1, -1]) cube([half, reach + 1, tall + 1]);
                        else translate([x0 - 1, lo, -1]) cube([reach + 1, half, tall + 1]);
                    }
                    split_bolt_holes(axis, c, axis == 0 ? cy : cx);
                }
            }
        }
    }

    for(ci = [0:len(xs)-2]) {
        for(rj = [0:len(ys)-2]) {
            tile_name = str(ci, "_", rj);
            if(split_tile == "all" || split_tile == tile_name) {
                translate(split_tile == "all" ? [ci*split_explode, rj*split_explode, 0] : [0, 0, 0])
                difference() {
                    union() {
                        intersection() {
                            children();
                            translate([xs[ci], ys[rj], -big/2]) cube([xs[ci+1] - xs[ci], ys[rj+1] - ys[rj], big]);
                        }
                        // flanges on every cut edge of this tile, trimmed to the tile
                        intersection() {
                            union() {
                                if(ci > 0) split_flange(0, xs[ci], 1) children();
                                if(ci < len(xs) - 2) split_flange(0, xs[ci+1], -1) children();
                                if(rj > 0) split_flange(1, ys[rj], 1) children();
                                if(rj < len(ys) - 2) split_flange(1, ys[rj+1], -1) children();
                            }
                            translate([xs[ci], ys[rj], -big/2]) cube([xs[ci+1] - xs[ci], ys[rj+1] - ys[rj], big]);
                        }
                    }
                    for(c = cx) split_bolt_holes(0, c, cy);
                    for(c = cy) split_bolt_holes(1, c, cx);
                }
            }
        }
    }
}
