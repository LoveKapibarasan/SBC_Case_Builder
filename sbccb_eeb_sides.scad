/*
    SBC Case Builder Vented Side Panels and Top Cover
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


           NAME: sbccb_eeb_sides
    DESCRIPTION: hex vented walls that close the sides of sbccb_eeb_panel.

                 four square corner posts stand just outside the base panel. the
                 walls lie against the outside of the posts and are screwed into
                 them with M3. the base panel is only 2.5 mm larger than the
                 board, so posts inside the base would hit the board.

                 every wall carries a lip along its inner bottom edge. the base
                 panel rests on the lips, which raises it off the desk so the
                 bottom vents can breathe, and is screwed to them from below
                 into pilot holes in its outer rib.

                 the rear wall has openings for the I/O shield and for the
                 expansion slot brackets. walls longer than the bed are split
                 and rejoined with the same butterfly keys as the base panel.

                 the top cover lies on the walls and posts, locates with a rim
                 that drops just inside the walls, and screws into the top of the
                 posts. it is split into a 2 x 2 grid joined with keys.

                 walls and top cover tiles print flat, outer face down, ribs, lip
                 and rim up, no support. posts print lying down.

           TODO: expansion card bracket retention
*/

    use <./sbccb_eeb_panel.scad>;

    /* [View] */
    // "model" assembled case, "part" single part
    view = "model"; // [model, part]
    // part shown when view is "part"
    part = "rear_0"; // [rear_0, rear_1, front_0, front_1, left_0, left_1, right_0, right_1, post, key, top_0_0, top_1_0, top_0_1, top_1_1]
    // show the base panel in the assembled model
    show_base = true; // [true,false]
    // show the motherboard outline in the assembled model
    show_board = true; // [true,false]
    // leave the front wall out of the model so the inside is visible
    cutaway = false; // [true,false]
    // show the top cover in the assembled model
    show_top = true; // [true,false]

    /* [Case] */
    // wall height from the desk
    case_height = 200; // [60:1:212]
    // height of the base lip above the desk, the air gap under the base
    foot_height = 10; // [4:1:40]

    /* [Wall] */
    // thickness of the vented field
    wall_field_t = 3; // [1.5:.5:8]
    // total wall thickness at the ribs
    wall_t = 6; // [3:.5:12]
    // width of the solid ribs along edges, seams and around openings
    wall_rib_w = 14; // [8:1:30]
    // thickness of the lip that carries the base
    lip_t = 4; // [3:.5:10]
    // corner post size
    post_s = 14; // [10:1:30]

    /* [Vent] */
    // hex cell size across the flats
    cell_size = 8; // [3:.5:25]
    // material left between cells
    cell_wall = 2.5; // [1:.25:8]

    /* [Rear Openings] */
    // cut the I/O shield window
    io_window = true; // [true,false]
    // I/O window left edge in board coordinates
    io_x = -1; // [-20:.1:100]
    // I/O window width, the ATX aperture is 158.75. the default runs into the slot
    // window so no thin sliver of wall is left between the two
    io_w = 162.5; // [100:.1:200]
    // I/O window bottom relative to the board top surface
    io_z = -3; // [-10:.1:10]
    // I/O window height, the ATX aperture is 44.45
    io_h = 48; // [30:.1:80]
    // cut the expansion slot window
    slot_window = true; // [true,false]
    // slot window left edge in board coordinates
    slot_x = 161.5; // [100:.1:300]
    // slot window width, 7 slots at 20.32 pitch span about 142
    slot_w = 143; // [20:.1:200]
    // slot window bottom relative to the board top surface
    slot_z = -3; // [-10:.1:10]
    // slot window height, a full height bracket is about 120
    slot_h = 118; // [30:.1:170]

    /* [Top Cover] */
    // position of the top cover vertical seam, 0 splits in half
    top_split_x = 0; // [0:.1:400]
    // position of the top cover horizontal seam, 0 splits in half
    top_split_y = 0; // [0:.1:400]
    // thickness of the top cover vented field
    top_field_t = 3; // [1.5:.5:8]
    // top cover thickness at the ribs
    top_t = 6; // [3:.5:12]
    // width of the perimeter rib, it has to cover the wall and the corner posts
    top_rib_w = 22; // [16:1:40]
    // depth of the locating rim that drops inside the walls
    top_rim_h = 8; // [0:.5:20]
    // thickness of the locating rim
    top_rim_t = 3; // [2:.5:6]
    // clearance between the rim and the inside of the walls
    top_rim_gap = 1; // [0:.1:3]
    // keys per seam per tile edge on the top cover
    top_keys_per_seam = 3; // [1:1:8]

    /* [Hidden] */
    adj = 0.01;
    $fn = 40;

    // base panel geometry, read from sbccb_eeb_panel so the two never drift apart
    panel_size = eeb_panel_size();
    px = panel_size[0];
    py = panel_size[1];
    base_rib_w = eeb_panel_rib_w();
    board_off = eeb_board_offset();
    key_dims = eeb_key_dims();
    key_len = key_dims[0];
    key_end = key_dims[1];
    key_depth = key_dims[2];
    key_waist = key_dims[3];

    // the base sits on the lips
    base_z = foot_height + lip_t;
    board_top_z = base_z + eeb_board_top_on_panel();
    // lip reaches across the post gap and under the base outer rib
    lip_depth = post_s + base_rib_w;

    hex_r = cell_size / sqrt(3);
    hex_p = cell_size + cell_wall;

    // lengths of the two wall families
    rf_len = px + 2*post_s;
    lr_len = py + 2*(post_s + wall_t);

    // post screw heights, the two families are offset so their holes never cross
    // inside a post
    post_v_rf = [for(f = [0.2, 0.5, 0.8]) case_height * f];
    post_v_lr = [for(f = [0.27, 0.57, 0.87]) case_height * f];

    // rear wall openings in wall coordinates [u, v, w, h]
    rear_openings = concat(
        io_window ? [[io_x + board_off[0] + post_s, board_top_z + io_z, io_w, io_h]] : [],
        slot_window ? [[slot_x + board_off[0] + post_s, board_top_z + slot_z, slot_w, slot_h]] : []);

    // lip screws, converted from panel coordinates to wall coordinates
    side_screws = eeb_side_screws();
    function lip_screw_u(name) =
        [for(s = side_screws) if(s[0] == name)
            (name == "rear" || name == "front") ? s[1] + post_s : s[1] + post_s + wall_t];

    /* wall description
       [length, seam u, openings, lip u from, lip u to, post screw u, post screw v,
        lip screw u, end band width] */
    function wall_desc(name) =
        (name == "rear" || name == "front")
        ? [rf_len,
           name == "rear" ? 150 : rf_len/2,
           name == "rear" ? rear_openings : [],
           post_s, post_s + px,
           [post_s/2, rf_len - post_s/2],
           post_v_rf,
           lip_screw_u(name),
           post_s]
        : [lr_len,
           lr_len/2,
           [],
           post_s + wall_t + base_rib_w, lr_len - post_s - wall_t - base_rib_w,
           [wall_t + post_s/2, lr_len - wall_t - post_s/2],
           post_v_lr,
           lip_screw_u(name),
           wall_t + post_s + 4];

    function wall_tile_range(name, ti) =
        let(d = wall_desc(name), s = [0, d[1], d[0]]) [s[ti], s[ti+1]];

    // keys along a seam, spread over the height and kept clear of the lip and
    // of every opening
    function key_clear(d, v) =
        v - key_end/2 > foot_height + lip_t + 1 &&
        v + key_end/2 < case_height - 1 &&
        len([for(o = d[2])
            if(d[1] + key_len/2 + 1 > o[0] && d[1] - key_len/2 - 1 < o[0] + o[2] &&
               v + key_end/2 + 1 > o[1] && v - key_end/2 - 1 < o[1] + o[3]) 1]) == 0;
    function wall_key_v(name) =
        let(d = wall_desc(name), n = 7, lo = key_end/2 + 2, hi = case_height - key_end/2 - 2)
            [for(k = [0:n]) let(v = lo + k*(hi - lo)/n) if(key_clear(d, v)) v];


/* 2D hex vents for one tile, only whole cells inside the inner area and clear of
   the rib bands around every opening */

module wall_vents_2d(x0, y0, x1, y1, openings) {

    py_ = hex_p * sqrt(3) / 2;
    nx = ceil((x1 - x0) / hex_p) + 1;
    ny = ceil((y1 - y0) / py_) + 1;
    m = wall_rib_w + hex_r;

    for(j = [0:ny]) {
        for(i = [0:nx]) {
            cx = x0 + i*hex_p + (j % 2)*hex_p/2;
            cy = y0 + j*py_;
            inside = cx - hex_r >= x0 && cx + hex_r <= x1 && cy - hex_r >= y0 && cy + hex_r <= y1;
            clear = len([for(o = openings)
                if(cx > o[0] - m && cx < o[0] + o[2] + m && cy > o[1] - m && cy < o[1] + o[3] + m) 1]) == 0;
            if(inside && clear) translate([cx, cy]) rotate([0,0,30]) circle(r=hex_r, $fn=6);
        }
    }
}


/* wall key pocket, open on the inner face */

module wall_key_pocket() {

    translate([0, 0, wall_t - key_depth])
        linear_extrude(height = key_depth + adj)
            polygon([[-key_len/2, -key_end/2], [0, -key_waist/2], [key_len/2, -key_end/2],
                     [key_len/2, key_end/2], [0, key_waist/2], [-key_len/2, key_end/2]]);
}


/* one wall tile in print orientation: u along x, height along y, outer face on
   the bed at z = 0, inner face and lip on top */

module wall_tile(name, ti) {

    d = wall_desc(name);
    r = wall_tile_range(name, ti);
    u0 = r[0];
    w = r[1] - r[0];
    last = ti == 1;
    ops = [for(o = d[2]) [o[0] - u0, o[1], o[2], o[3]]];
    lb = ti == 0 ? d[8] : wall_rib_w;
    rb = last ? d[8] : wall_rib_w;
    bb = max(wall_rib_w, foot_height + lip_t + 2);
    tb = wall_rib_w;

    difference() {
        union() {
            // vented field
            linear_extrude(height = wall_field_t)
                difference() {
                    square([w, case_height]);
                    wall_vents_2d(lb, bb, w - rb, case_height - tb, ops);
                }
            // ribs round the tile edge and round every opening
            linear_extrude(height = wall_t)
                intersection() {
                    square([w, case_height]);
                    union() {
                        difference() {
                            square([w, case_height]);
                            translate([lb, bb]) square([w - lb - rb, case_height - bb - tb]);
                        }
                        for(o = ops) translate([o[0] - wall_rib_w, o[1] - wall_rib_w])
                            square([o[2] + 2*wall_rib_w, o[3] + 2*wall_rib_w]);
                    }
                }
            // lip, trimmed to this tile
            a = max(d[3] - u0, 0);
            b = min(d[4] - u0, w);
            if(b > a) translate([a, foot_height, wall_t - adj]) cube([b - a, lip_t, lip_depth + adj]);
        }
        // openings through everything
        for(o = ops) translate([o[0], o[1], -1]) cube([o[2], o[3], wall_t + lip_depth + 2]);
        // post screws through the wall
        for(pu = d[5]) if(pu >= u0 && pu < u0 + w) for(pv = d[6]) {
            translate([pu - u0, pv, -adj]) cylinder(d=3.4, h=wall_t + 2*adj);
        }
        // lip screws up through the lip into the base rib
        for(lu = d[7]) if(lu >= u0 && lu < u0 + w) {
            translate([lu - u0, foot_height - adj, wall_t + post_s + base_rib_w/2])
                rotate([-90,0,0]) cylinder(d=3.4, h=lip_t + 2*adj);
        }
        // key pockets on the seam edge
        if(ti == 0) for(v = wall_key_v(name)) translate([w, v, 0]) wall_key_pocket();
        if(ti == 1) for(v = wall_key_v(name)) translate([0, v, 0]) wall_key_pocket();
    }
}


/* wall key, printed flat */

module wall_key() {

    linear_extrude(height = key_depth - 0.2)
        offset(delta = -0.1)
            polygon([[-key_len/2, -key_end/2], [0, -key_waist/2], [key_len/2, -key_end/2],
                     [key_len/2, key_end/2], [0, key_waist/2], [-key_len/2, key_end/2]]);
}


/* corner post. rear and front walls screw into the y faces, left and right walls
   into the x faces, at different heights, so one part fits every corner. the top
   cover screws into the top end */

module corner_post() {

    difference() {
        cube([post_s, post_s, case_height]);
        for(v = post_v_rf) translate([post_s/2, -adj, v]) rotate([-90,0,0])
            cylinder(d=2.6, h=post_s + 2*adj);
        for(v = post_v_lr) translate([-adj, post_s/2, v]) rotate([0,90,0])
            cylinder(d=2.6, h=post_s + 2*adj);
        translate([post_s/2, post_s/2, case_height - top_pilot_depth])
            cylinder(d=2.6, h=top_pilot_depth + adj);
    }
}


/* top cover. covers the whole case outline, its perimeter rib lies on the walls
   and posts, a locating rim drops just inside the walls between the posts, and it
   screws into the top of each post. split into tiles joined with keys like the
   walls. print orientation: outer face on the bed, ribs and rim up */

    top_x = px + 2*(post_s + wall_t);
    top_y = py + 2*(post_s + wall_t);
    top_edges_x = [0, top_split_x > 0 ? top_split_x : top_x/2, top_x];
    top_edges_y = [0, top_split_y > 0 ? top_split_y : top_y/2, top_y];
    top_pilot_depth = 12;

    // post centres in top cover coordinates
    top_post_c = wall_t + post_s/2;
    top_screws = [[top_post_c, top_post_c], [top_x - top_post_c, top_post_c],
                  [top_post_c, top_y - top_post_c], [top_x - top_post_c, top_y - top_post_c]];

    // rim segments between the posts [x, y, w, h]
    rim_in = wall_t + top_rim_gap;
    rim_end = wall_t + post_s + top_rim_gap;
    top_rims = top_rim_h <= 0 ? [] : [
        [rim_end, rim_in, top_x - 2*rim_end, top_rim_t],
        [rim_end, top_y - rim_in - top_rim_t, top_x - 2*rim_end, top_rim_t],
        [rim_in, rim_end, top_rim_t, top_y - 2*rim_end],
        [top_x - rim_in - top_rim_t, rim_end, top_rim_t, top_y - 2*rim_end]];

    function top_key_pos(len) = [for(k = [1:top_keys_per_seam]) len * k / (top_keys_per_seam + 1)];
    function top_key_count() = 4 * top_keys_per_seam;

    for(e = [top_edges_x[1], top_x - top_edges_x[1], top_edges_y[1], top_y - top_edges_y[1]])
        if(e > 212) echo(str("WARNING: a top cover tile is ", e, " mm, larger than a 220 bed allows"));


module key_pocket_at(thick) {

    translate([0, 0, thick - key_depth])
        linear_extrude(height = key_depth + adj)
            polygon([[-key_len/2, -key_end/2], [0, -key_waist/2], [key_len/2, -key_end/2],
                     [key_len/2, key_end/2], [0, key_waist/2], [-key_len/2, key_end/2]]);
}


module top_tile(ci, rj) {

    x0 = top_edges_x[ci];
    y0 = top_edges_y[rj];
    w = top_edges_x[ci+1] - x0;
    h = top_edges_y[rj+1] - y0;
    lb = ci == 0 ? top_rib_w : wall_rib_w;
    rb = ci == 1 ? top_rib_w : wall_rib_w;
    bb = rj == 0 ? top_rib_w : wall_rib_w;
    tb = rj == 1 ? top_rib_w : wall_rib_w;

    difference() {
        union() {
            linear_extrude(height = top_field_t)
                difference() {
                    square([w, h]);
                    wall_vents_2d(lb, bb, w - rb, h - tb, []);
                }
            linear_extrude(height = top_t)
                difference() {
                    square([w, h]);
                    translate([lb, bb]) square([w - lb - rb, h - bb - tb]);
                }
            // locating rim, trimmed to this tile
            intersection() {
                translate([0, 0, top_t - adj]) cube([w, h, top_rim_h + adj]);
                for(r = top_rims) translate([r[0] - x0, r[1] - y0, 0]) cube([r[2], r[3], top_t + top_rim_h]);
            }
        }
        // post screws, countersunk into the outer face
        for(s = top_screws) {
            lx = s[0] - x0;
            ly = s[1] - y0;
            if(lx >= 0 && lx < w && ly >= 0 && ly < h) {
                translate([lx, ly, -adj]) cylinder(d=3.4, h=top_t + 2*adj);
                translate([lx, ly, -adj]) cylinder(d1=6.8, d2=3.4, h=1.7);
            }
        }
        // key pockets on seam edges
        if(ci == 0) for(y = top_key_pos(h)) translate([w, y, 0]) key_pocket_at(top_t);
        if(ci == 1) for(y = top_key_pos(h)) translate([0, y, 0]) key_pocket_at(top_t);
        if(rj == 0) for(x = top_key_pos(w)) translate([x, h, 0]) rotate([0,0,90]) key_pocket_at(top_t);
        if(rj == 1) for(x = top_key_pos(w)) translate([x, 0, 0]) rotate([0,0,90]) key_pocket_at(top_t);
    }
}


/* whole top cover in print orientation, with keys */

module top_cover() {

    for(ci = [0:1]) for(rj = [0:1])
        translate([top_edges_x[ci], top_edges_y[rj], 0]) top_tile(ci, rj);
    color("#d98b4a") {
        for(rj = [0:1]) for(y = top_key_pos(top_edges_y[rj+1] - top_edges_y[rj]))
            translate([top_edges_x[1], top_edges_y[rj] + y, top_t - key_depth]) wall_key();
        for(ci = [0:1]) for(x = top_key_pos(top_edges_x[ci+1] - top_edges_x[ci]))
            translate([top_edges_x[ci] + x, top_edges_y[1], top_t - key_depth]) rotate([0,0,90]) wall_key();
    }
}


/* place a wall from print orientation into case coordinates */

module place_wall(name) {

    m = name == "rear"  ? [[1,0,0,-post_s], [0,0,1,-(post_s + wall_t)], [0,1,0,0]] :
        name == "front" ? [[1,0,0,-post_s], [0,0,-1, py + post_s + wall_t], [0,1,0,0]] :
        name == "left"  ? [[0,0,1,-(post_s + wall_t)], [1,0,0,-(post_s + wall_t)], [0,1,0,0]] :
                          [[0,0,-1, px + post_s + wall_t], [1,0,0,-(post_s + wall_t)], [0,1,0,0]];
    multmatrix(m) children();
}


module whole_wall(name) {

    for(ti = [0:1]) translate([wall_tile_range(name, ti)[0], 0, 0]) wall_tile(name, ti);
    // keys in place
    color("#d98b4a")
        for(v = wall_key_v(name))
            translate([wall_desc(name)[1], v, wall_t - key_depth]) wall_key();
}


/* assembled case */

module case_model() {

    if(show_base) translate([0, 0, base_z]) panel_model();
    if(show_board) translate([0, 0, base_z]) board_outline();

    for(name = cutaway ? ["rear", "left", "right"] : ["rear", "front", "left", "right"]) {
        color("#5fa8e8", 0.95) place_wall(name) whole_wall(name);
    }
    color("#777777") {
        translate([-post_s, -post_s, 0]) corner_post();
        translate([px, -post_s, 0]) corner_post();
        translate([-post_s, py, 0]) corner_post();
        translate([px, py, 0]) corner_post();
    }
    // top cover flipped from print orientation, ribs down onto the walls
    if(show_top) {
        color("#4a90d9", 0.9)
            translate([-(post_s + wall_t), -(post_s + wall_t), case_height + top_t])
                mirror([0,0,1]) top_cover();
    }
}


echo(str("board top at ", board_top_z, " mm, clearance above the board ", case_height - board_top_z, " mm"));
echo(str("case outline ", px + 2*(post_s + wall_t), " x ", py + 2*(post_s + wall_t), " x ", case_height, " mm"));


/* main */

if(view == "model") case_model();
if(view == "part") {
    if(part == "rear_0")  wall_tile("rear", 0);
    if(part == "rear_1")  wall_tile("rear", 1);
    if(part == "front_0") wall_tile("front", 0);
    if(part == "front_1") wall_tile("front", 1);
    if(part == "left_0")  wall_tile("left", 0);
    if(part == "left_1")  wall_tile("left", 1);
    if(part == "right_0") wall_tile("right", 0);
    if(part == "right_1") wall_tile("right", 1);
    if(part == "post")    corner_post();
    if(part == "key")     wall_key();
    if(part == "top_0_0") top_tile(0, 0);
    if(part == "top_1_0") top_tile(1, 0);
    if(part == "top_0_1") top_tile(0, 1);
    if(part == "top_1_1") top_tile(1, 1);
}
