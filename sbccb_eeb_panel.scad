/*
    SBC Case Builder Vented Split Panel
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


           NAME: sbccb_eeb_panel
    DESCRIPTION: hex vented base panel of any size, split into tiles that fit the
                 print bed. defaults to a 309.8 x 335.2 base for SSI-EEB (and so
                 E-ATX / ATX) motherboards with the 11 standoffs built in.

                 tiles butt together and are locked with printed butterfly keys
                 that drop in vertically, so a 2 x 2 grid assembles in any order.

                 each tile is a thin hex field inside a thicker perimeter rib.
                 standoffs sit on solid pads cut out of the hex field. the board
                 screws straight into the standoffs with M3 screws, nothing else
                 needs fastening.

                 the tile seams are placed with split_x / split_y. with equal
                 splits three standoffs land exactly on the horizontal seam, the
                 defaults keep every standoff at least 30 mm from any seam.

                 everything prints flat side down, standoffs up, no support.

           TODO: side panels
*/

    /* [View] */
    // "model" assembled panel, "platter" tiles and keys laid out, "part" single part
    view = "model"; // [model, platter, part]
    // part shown when view is "part"
    part = "tile"; // [tile, key]
    // which tile to show when part is "tile", column index from the left
    tile_col = 0; // [0:1:5]
    // which tile to show when part is "tile", row index from the front
    tile_row = 0; // [0:1:5]
    // show the seam keys in the assembled model
    show_keys = true; // [true,false]
    // show the motherboard outline in the assembled model
    show_board = false; // [true,false]

    /* [Panel] */
    // overall panel width
    panel_x = 309.8; // [50:.1:800]
    // overall panel depth
    panel_y = 335.2; // [50:.1:800]
    // thickness of the vented field
    panel_t = 3; // [1.5:.5:8]
    // width of the solid rib around each tile
    rib_w = 14; // [8:1:30]
    // total thickness at the rib
    rib_t = 6; // [3:.5:15]
    // position of the vertical seam, 0 splits equally to fit the bed
    split_x = 130; // [0:.1:800]
    // position of the horizontal seam, 0 splits equally to fit the bed
    split_y = 135; // [0:.1:800]

    /* [Vent] */
    // hex cell size across the flats
    cell_size = 8; // [3:.5:25]
    // material left between cells
    cell_wall = 2.5; // [1:.25:8]

    /* [Standoffs] */
    // "none" plain panel, "ssi-eeb" 11 standoffs for SSI-EEB / E-ATX / ATX boards
    mount = "ssi-eeb"; // [none, ssi-eeb]
    // board rear left corner measured from the panel corner
    board_offset_x = 2.5; // [0:.1:100]
    // board rear left corner measured from the panel corner
    board_offset_y = 2.5; // [0:.1:100]
    // standoff height above the pad
    standoff_height = 8; // [3:.5:30]
    // standoff diameter
    standoff_dia = 9; // [6:.5:16]
    // screw hole, 2.6 lets an M3 cut its own thread
    standoff_hole = 2.6; // [1.5:.1:5]
    // radius of the solid pad kept free of vents around each standoff
    pad_r = 9; // [5:.5:20]
    // board thickness, reference model only
    board_t = 1.6; // [1:.1:3]

    /* [Print Bed] */
    // usable bed width
    bed_x = 220; // [100:1:400]
    // usable bed depth
    bed_y = 220; // [100:1:400]
    // margin kept clear at the bed edges
    bed_margin = 8; // [0:1:40]
    // gap between parts on the platter
    platter_gap = 8; // [2:1:30]

    /* [Seam Keys] */
    // butterfly key length across the seam
    key_len = 24; // [12:1:60]
    // butterfly key width at its wide ends
    key_end = 12; // [6:1:40]
    // butterfly key width at its waist
    key_waist = 7; // [3:1:30]
    // depth of the key pocket in the rib
    key_depth = 4; // [2:.5:10]
    // clearance per face between key and pocket
    key_fit = 0.1; // [0:.05:.5]
    // keys per seam per tile edge
    keys_per_seam = 3; // [1:1:8]

    /* [Hidden] */
    adj = 0.01;
    $fn = 60;

    board_x = 304.8;
    board_y = 330.2;

    // SSI-EEB mounting holes, source SBC_Model_Framework/sbc_models.cfg "ssi-eeb"
    // [name, x, y] measured from the rear left corner of the pcb
    eeb_holes = [
        ["left_rear",        6.35,  33.02],
        ["middle_rear",    163.83,  10.16],
        ["right_rear",     288.29,  10.16],
        ["left_middle",      6.35, 165.10],
        ["middle_middle",  163.83, 165.10],
        ["right_middle",   288.29, 165.10],
        ["middle2_middle", 209.55, 187.96],
        ["right_middle2",  288.29, 237.49],
        ["left_front",       6.35, 322.58],
        ["middle_front",   163.83, 322.88],
        ["right_front",    299.72, 322.58]
    ];

    // standoff centres in panel coordinates
    standoffs = mount == "ssi-eeb"
        ? [for(h = eeb_holes) [h[1] + board_offset_x, h[2] + board_offset_y]]
        : [];

    // tile edges along each axis
    cols_auto = ceil(panel_x / (bed_x - bed_margin));
    rows_auto = ceil(panel_y / (bed_y - bed_margin));
    edges_x = split_x > 0 ? [0, split_x, panel_x] : [for(i = [0:cols_auto]) i * panel_x / cols_auto];
    edges_y = split_y > 0 ? [0, split_y, panel_y] : [for(j = [0:rows_auto]) j * panel_y / rows_auto];
    cols = len(edges_x) - 1;
    rows = len(edges_y) - 1;
    function tw(ci) = edges_x[ci+1] - edges_x[ci];
    function th(rj) = edges_y[rj+1] - edges_y[rj];

    // hex lattice, centre to centre distance between neighbouring cells
    hex_r = cell_size / sqrt(3);
    hex_p = cell_size + cell_wall;

    for(ci = [0:cols-1]) if(tw(ci) > bed_x - bed_margin)
        echo(str("WARNING: tile column ", ci, " is ", tw(ci), " mm, wider than the usable bed"));
    for(rj = [0:rows-1]) if(th(rj) > bed_y - bed_margin)
        echo(str("WARNING: tile row ", rj, " is ", th(rj), " mm, deeper than the usable bed"));


/* standoffs that fall inside tile ci, rj, in tile local coordinates */

function tile_standoffs(ci, rj) =
    [for(s = standoffs)
        if(s[0] >= edges_x[ci] && s[0] < edges_x[ci+1] && s[1] >= edges_y[rj] && s[1] < edges_y[rj+1])
            [s[0] - edges_x[ci], s[1] - edges_y[rj]]];


/* triangular lattice of hex holes as a 2D shape, only whole cells that fit
   inside w x h and clear of every point in avoid by pad_r. kept in 2D so the
   boolean stays cheap enough to preview */

module hex_field_2d(w, h, avoid = []) {

    py = hex_p * sqrt(3) / 2;
    nx = ceil(w / hex_p) + 1;
    ny = ceil(h / py) + 1;

    for(j = [0:ny]) {
        for(i = [0:nx]) {
            cx = i * hex_p + (j % 2) * hex_p / 2;
            cy = j * py;
            inside = cx - hex_r >= 0 && cx + hex_r <= w && cy - hex_r >= 0 && cy + hex_r <= h;
            clear = len([for(a = avoid) if(norm([cx - a[0], cy - a[1]]) < pad_r + hex_r) 1]) == 0;
            if(inside && clear) {
                translate([cx, cy]) rotate([0,0,30]) circle(r=hex_r, $fn=6);
            }
        }
    }
}


/* butterfly key outline, long axis along x, centred on the origin */

module key_outline(shrink = 0) {

    offset(delta = -shrink)
        polygon([[-key_len/2, -key_end/2], [0, -key_waist/2], [key_len/2, -key_end/2],
                 [key_len/2, key_end/2], [0, key_waist/2], [-key_len/2, key_end/2]]);
}


/* the printed key itself */

module seam_key() {

    linear_extrude(height = key_depth - 0.2) key_outline(key_fit);
}


/* pocket cut into the rib, open at the top */

module key_pocket() {

    translate([0, 0, rib_t - key_depth])
        linear_extrude(height = key_depth + adj) key_outline(0);
}


/* positions of the keys along one tile edge of length len */

function key_positions(len) =
    [for(k = [1:keys_per_seam]) len * k / (keys_per_seam + 1)];


/* one tile. ci and rj are its column and row in the panel grid */

module panel_tile(ci, rj) {

    w = tw(ci);
    h = th(rj);
    pts = tile_standoffs(ci, rj);
    avoid = [for(p = pts) [p[0] - rib_w, p[1] - rib_w]];

    intersection() {
        difference() {
            union() {
                // vented field over the whole tile, vents cut in 2D then extruded
                linear_extrude(height = panel_t)
                    difference() {
                        square([w, h]);
                        translate([rib_w, rib_w]) hex_field_2d(w - 2*rib_w, h - 2*rib_w, avoid);
                    }
                // solid rib around the perimeter
                linear_extrude(height = rib_t)
                    difference() {
                        square([w, h]);
                        translate([rib_w, rib_w]) square([w - 2*rib_w, h - 2*rib_w]);
                    }
                // standoff pads and pillars
                for(p = pts) {
                    translate([p[0], p[1], 0]) cylinder(r=pad_r, h=rib_t);
                    translate([p[0], p[1], 0]) cylinder(d=standoff_dia, h=rib_t + standoff_height);
                }
            }
            // key pockets, only on edges shared with another tile
            if(ci > 0) {
                for(y = key_positions(h)) translate([0, y, 0]) key_pocket();
            }
            if(ci < cols - 1) {
                for(y = key_positions(h)) translate([w, y, 0]) key_pocket();
            }
            if(rj > 0) {
                for(x = key_positions(w)) translate([x, 0, 0]) rotate([0,0,90]) key_pocket();
            }
            if(rj < rows - 1) {
                for(x = key_positions(w)) translate([x, h, 0]) rotate([0,0,90]) key_pocket();
            }
            // board screw holes, through so any screw length works
            for(p = pts) {
                translate([p[0], p[1], -adj]) cylinder(d=standoff_hole, h=rib_t + standoff_height + 2*adj);
            }
        }
        // pads near the panel edge are trimmed to the tile
        translate([0, 0, -1]) cube([w, h, rib_t + standoff_height + 2]);
    }
}


/* every key in the assembled panel, in place */

module panel_keys() {

    z = rib_t - key_depth;
    if(cols > 1) {
        for(ci = [1:cols-1]) for(rj = [0:rows-1]) for(y = key_positions(th(rj))) {
            translate([edges_x[ci], edges_y[rj] + y, z]) seam_key();
        }
    }
    if(rows > 1) {
        for(rj = [1:rows-1]) for(ci = [0:cols-1]) for(x = key_positions(tw(ci))) {
            translate([edges_x[ci] + x, edges_y[rj], z]) rotate([0,0,90]) seam_key();
        }
    }
}


function key_count() =
    (cols - 1) * rows * keys_per_seam + (rows - 1) * cols * keys_per_seam;


/* reference motherboard */

module board_outline() {

    color("#1d5c3a", 0.35)
    translate([board_offset_x, board_offset_y, rib_t + standoff_height])
        difference() {
            cube([board_x, board_y, board_t]);
            for(h = eeb_holes) translate([h[1], h[2], -1]) cylinder(d=3.5, h=board_t+2);
        }
}


/* assembled panel */

module panel_model() {

    for(ci = [0:cols-1]) {
        for(rj = [0:rows-1]) {
            color((ci + rj) % 2 == 0 ? "#4a90d9" : "#5fa8e8")
                translate([edges_x[ci], edges_y[rj], 0]) panel_tile(ci, rj);
        }
    }
    if(show_keys) color("#d98b4a") panel_keys();
    if(show_board && mount == "ssi-eeb") board_outline();
}


/* platter. tiles are larger than half a bed, so print one tile per batch */

module panel_platter() {

    for(ci = [0:cols-1]) {
        for(rj = [0:rows-1]) {
            translate([edges_x[ci] + ci*platter_gap, edges_y[rj] + rj*platter_gap, 0])
                panel_tile(ci, rj);
        }
    }
    // the whole key set fits next to the tiles
    kx = panel_x + cols*platter_gap;
    for(k = [0:key_count()-1]) {
        translate([kx + floor(k/8)*(key_len + platter_gap) + key_len/2,
                   (k % 8)*(key_end + platter_gap) + key_end/2, 0]) seam_key();
    }
}


/* main */

if(view == "model") panel_model();
if(view == "platter") panel_platter();
if(view == "part") {
    if(part == "tile") panel_tile(tile_col, tile_row);
    if(part == "key")  seam_key();
}
