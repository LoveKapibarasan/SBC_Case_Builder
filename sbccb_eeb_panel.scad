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
    DESCRIPTION: hex vented cover panel of any size, automatically split into
                 tiles that fit the print bed. defaults to the footprint of
                 sbccb_eeb_frame, 309.8 x 335.2.

                 no bought hardware. tiles butt together and are locked with
                 printed butterfly keys that drop in vertically, so a 2 x 2 tile
                 grid assembles without having to slide any tile into place.

                 each tile is a thin hex field with a thicker solid rib around
                 its perimeter. ribs double up along every seam, giving a solid
                 band deep enough to host the key pockets and stiffening the
                 finished panel.

                 everything prints flat side down with no support.

           TODO: attachment to the frame, side panels
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

    /* [Panel] */
    // overall panel width, default matches the sbccb_eeb_frame outline
    panel_x = 309.8; // [50:.1:800]
    // overall panel depth, default matches the sbccb_eeb_frame outline
    panel_y = 335.2; // [50:.1:800]
    // thickness of the vented field
    panel_t = 3; // [1.5:.5:8]
    // width of the solid rib around each tile
    rib_w = 14; // [8:1:30]
    // total thickness at the rib
    rib_t = 6; // [3:.5:15]

    /* [Vent] */
    // hex cell size across the flats
    cell_size = 8; // [3:.5:25]
    // material left between cells
    cell_wall = 2.5; // [1:.25:8]

    /* [Print Bed] */
    // usable bed width
    bed_x = 220; // [100:1:400]
    // usable bed depth
    bed_y = 220; // [100:1:400]
    // margin kept clear at the bed edges when deciding the tile count
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

    // tile grid, chosen so that every tile fits the usable bed
    cols = ceil(panel_x / (bed_x - bed_margin));
    rows = ceil(panel_y / (bed_y - bed_margin));
    tile_w = panel_x / cols;
    tile_h = panel_y / rows;

    // hex lattice, centre to centre distance between neighbouring cells
    hex_r = cell_size / sqrt(3);
    hex_p = cell_size + cell_wall;


/* triangular lattice of hex holes as a 2D shape, only whole cells that fit
   inside w x h. kept in 2D so the boolean stays cheap enough to preview */

module hex_field_2d(w, h) {

    py = hex_p * sqrt(3) / 2;
    nx = ceil(w / hex_p) + 1;
    ny = ceil(h / py) + 1;

    for(j = [0:ny]) {
        for(i = [0:nx]) {
            cx = i * hex_p + (j % 2) * hex_p / 2;
            cy = j * py;
            if(cx - hex_r >= 0 && cx + hex_r <= w && cy - hex_r >= 0 && cy + hex_r <= h) {
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

    difference() {
        union() {
            // vented field over the whole tile, vents cut in 2D then extruded
            linear_extrude(height = panel_t)
                difference() {
                    square([tile_w, tile_h]);
                    translate([rib_w, rib_w])
                        hex_field_2d(tile_w - 2*rib_w, tile_h - 2*rib_w);
                }
            // solid rib around the perimeter
            linear_extrude(height = rib_t)
                difference() {
                    square([tile_w, tile_h]);
                    translate([rib_w, rib_w]) square([tile_w - 2*rib_w, tile_h - 2*rib_w]);
                }
        }
        // key pockets, only on edges shared with another tile
        if(ci > 0) {
            for(y = key_positions(tile_h)) translate([0, y, 0]) key_pocket();
        }
        if(ci < cols - 1) {
            for(y = key_positions(tile_h)) translate([tile_w, y, 0]) key_pocket();
        }
        if(rj > 0) {
            for(x = key_positions(tile_w)) translate([x, 0, 0]) rotate([0,0,90]) key_pocket();
        }
        if(rj < rows - 1) {
            for(x = key_positions(tile_w)) translate([x, tile_h, 0]) rotate([0,0,90]) key_pocket();
        }
    }
}


/* every key in the assembled panel, in place */

module panel_keys() {

    z = rib_t - key_depth;
    // keys on the vertical seams
    for(ci = [1:max(cols-1,0)]) {
        if(cols > 1) {
            for(rj = [0:rows-1]) {
                for(y = key_positions(tile_h)) {
                    translate([ci*tile_w, rj*tile_h + y, z]) seam_key();
                }
            }
        }
    }
    // keys on the horizontal seams
    for(rj = [1:max(rows-1,0)]) {
        if(rows > 1) {
            for(ci = [0:cols-1]) {
                for(x = key_positions(tile_w)) {
                    translate([ci*tile_w + x, rj*tile_h, z]) rotate([0,0,90]) seam_key();
                }
            }
        }
    }
}


function key_count() =
    (cols - 1) * rows * keys_per_seam + (rows - 1) * cols * keys_per_seam;


/* assembled panel */

module panel_model() {

    for(ci = [0:cols-1]) {
        for(rj = [0:rows-1]) {
            color((ci + rj) % 2 == 0 ? "#4a90d9" : "#5fa8e8")
                translate([ci*tile_w, rj*tile_h, 0]) panel_tile(ci, rj);
        }
    }
    if(show_keys) color("#d98b4a") panel_keys();
}


/* platter. tiles are larger than half a bed, so print one tile per batch */

module panel_platter() {

    for(ci = [0:cols-1]) {
        for(rj = [0:rows-1]) {
            translate([ci*(tile_w + platter_gap), rj*(tile_h + platter_gap), 0])
                panel_tile(ci, rj);
        }
    }
    // the whole key set fits next to the tiles
    kx = cols*(tile_w + platter_gap);
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
