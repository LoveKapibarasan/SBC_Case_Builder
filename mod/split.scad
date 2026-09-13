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
    DESCRIPTION: splits the top or bottom of a shell case into tiles that fit a
                 print bed. every cut gets a flange on each side, standing up from
                 the floor and running up the walls, and the two flanges are bolted
                 back to back with M3. cut positions are chosen automatically to
                 keep clear of the sbc mounting holes.
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

// a cut is needed when the part does not fit the usable bed along that axis
function split_needed(ln, bed) = ln > bed - split_bed_margin;

// clearance of a candidate cut from every mounting hole
function split_clear(c, holes) = len(holes) == 0 ? 1000 : min([for(h = holes) abs(h - c)]);

/* cut position along one axis. a manual value is measured from the part's outer
   edge. otherwise the search starts at the centre and walks outward, taking the
   first position that keeps split_hole_clear from every hole while both tiles
   still fit the bed */
function split_cut(axis) =
    let(o = axis == 0 ? split_x0() : split_y0(),
        ln = axis == 0 ? width : depth,
        bed = (axis == 0 ? split_bed_x : split_bed_y) - split_bed_margin,
        manual = axis == 0 ? split_x : split_y,
        holes = split_hole_axis(axis),
        lo = o + ln - bed,
        hi = o + bed,
        cands = [for(d = [0:1:ln/2]) for(c = [o + ln/2 - d, o + ln/2 + d])
                    if(c >= lo && c <= hi && (len(holes) == 0 || split_clear(c, holes) >= split_hole_clear)) c])
    manual > 0 ? o + manual : len(cands) > 0 ? cands[0] : o + ln/2;


/* flange cross section for a cut normal to axis, as a 2D shape in the plane of
   the cut. u runs along the cut, v is height */

module split_flange_2d(axis) {

    h = split_height();
    // inner wall faces along the cut direction
    u0 = axis == 0 ? split_y0() + wallthick : split_x0() + wallthick;
    u1 = axis == 0 ? split_y0() + depth - wallthick : split_x0() + width - wallthick;
    fh = split_flange_h;

    union() {
        // along the floor
        translate([u0, 0]) square([u1 - u0, floorthick + fh]);
        // up each wall
        translate([u0, 0]) square([fh, h]);
        translate([u1 - fh, 0]) square([fh, h]);
    }
}


/* bolt positions in a flange, [u, v] in the plane of the cut */

function split_bolts(axis, other_cut) =
    let(h = split_height(),
        u0 = (axis == 0 ? split_y0() : split_x0()) + wallthick,
        u1 = (axis == 0 ? split_y0() + depth : split_x0() + width) - wallthick,
        fh = split_flange_h,
        vf = floorthick + fh/2,
        n = max(2, floor((u1 - u0 - 2*fh) / split_bolt_spacing) + 1),
        floor_bolts = [for(k = [0:n-1])
            let(u = u0 + fh + split_bolt_edge + k*(u1 - u0 - 2*fh - 2*split_bolt_edge)/(n-1))
                if(other_cut == undef || abs(u - other_cut) > split_flange_t + 4) [u, vf]],
        // at least one bolt up each wall once the wall is tall enough to take it
        wall_free = h - floorthick - fh - split_bolt_edge,
        nv = wall_free < 2*split_bolt_edge ? 0 : max(1, floor(wall_free / split_bolt_spacing)),
        wall_bolts = nv < 1 ? [] :
            [for(k = [1:nv]) for(u = [u0 + fh/2, u1 - fh/2])
                [u, floorthick + fh + k*(h - floorthick - fh)/(nv+1)]])
    concat(floor_bolts, wall_bolts);


/* flange solid on one side of the cut. side is -1 for the low tile, +1 for the high */

module split_flange(axis, cut, side) {

    t = split_flange_t;
    if(axis == 0) {
        translate([side < 0 ? cut - t : cut, 0, 0])
            rotate([90, 0, 90]) linear_extrude(height = t) split_flange_2d(0);
    }
    else {
        translate([0, side < 0 ? cut : cut + t, 0])
            rotate([90, 0, 0]) linear_extrude(height = t) split_flange_2d(1);
    }
}


module split_bolt_holes(axis, cut, other_cut) {

    t = split_flange_t;
    for(b = split_bolts(axis, other_cut)) {
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
    cut_x = split_needed(width, split_bed_x) ? split_cut(0) : undef;
    cut_y = split_needed(depth, split_bed_y) ? split_cut(1) : undef;
    xs = cut_x == undef ? [x0 - 1000, x0 + width + 1000] : [x0 - 1000, cut_x, x0 + width + 1000];
    ys = cut_y == undef ? [y0 - 1000, y0 + depth + 1000] : [y0 - 1000, cut_y, y0 + depth + 1000];
    big = 1000;

    echo(split_cut_x = cut_x == undef ? "none" : cut_x - x0, split_cut_y = cut_y == undef ? "none" : cut_y - y0);
    if(cut_x != undef) echo(split_cut_x_hole_clearance = split_clear(cut_x, split_hole_axis(0)));
    if(cut_y != undef) echo(split_cut_y_hole_clearance = split_clear(cut_y, split_hole_axis(1)));

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
                        // flanges on the cut edges of this tile, trimmed to the tile
                        intersection() {
                            union() {
                                if(cut_x != undef) split_flange(0, cut_x, ci == 0 ? -1 : 1);
                                if(cut_y != undef) split_flange(1, cut_y, rj == 0 ? -1 : 1);
                            }
                            translate([xs[ci], ys[rj], -big/2]) cube([xs[ci+1] - xs[ci], ys[rj+1] - ys[rj], big]);
                        }
                    }
                    if(cut_x != undef) split_bolt_holes(0, cut_x, cut_y);
                    if(cut_y != undef) split_bolt_holes(1, cut_y, cut_x);
                }
            }
        }
    }
}
