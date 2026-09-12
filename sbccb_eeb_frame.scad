/*
    SBC Case Builder SSI-EEB Split Open Frame
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


           NAME: sbccb_eeb_frame
    DESCRIPTION: bolt together open frame for SSI-EEB (304.8 x 330.2) motherboards,
                 split into segments that fit a 220 x 220 print bed. SSI-EEB is the
                 largest standard footprint and its hole pattern is a superset of
                 E-ATX and ATX, so those boards mount on this frame as well.

                 ladder frame, 2 longitudinal rails x 3 cross rails, every rail
                 split in two and rejoined with a bolted half lap. all rails print
                 flat on the bed, standoffs up, no support material. feet are
                 separate parts that bolt to the underside of the longitudinal rails.

                 parts: 4 longitudinal segments, 6 cross segments, 4 feet.

           TODO: optional io shield bracket, psu and drive mounts
*/

    include <./lib/standoff.scad>;

    /* [View] */
    // "model" assembled frame, "platter" all parts arranged for printing, "part" single part
    view = "platter"; // [model, platter, part]
    // part shown when view is "part"
    part = "long_left_rear"; // [long_left_rear, long_left_front, long_right_rear, long_right_front, cross_rear_left, cross_rear_right, cross_middle_left, cross_middle_right, cross_front_left, cross_front_right, foot, pillar]
    // show the motherboard outline for reference, "model" view only
    show_board = true; // [true,false]
    // "frame" bolt together ladder frame, "pillars" free standing standoff towers only
    build = "frame"; // [frame, pillars]

    /* [Print Bed] */
    // usable bed width, used by the platter layout only
    bed_x = 220; // [100:1:400]
    // usable bed depth, used by the platter layout only
    bed_y = 220; // [100:1:400]
    // gap between parts on the platter
    platter_gap = 6; // [2:1:20]

    /* [Rail] */
    // rail width
    rail_w = 16; // [10:1:30]
    // rail thickness
    rail_h = 10; // [6:.5:20]

    /* [Standoff] */
    // standoff height above the rail, 6.35 is the ATX nominal
    standoff_height = 8; // [5:.5:20]
    // standoff pillar diameter
    standoff_dia = 8; // [6:.5:14]
    // "tap" M3 cuts its own thread, "nut" clearance hole with a hex pocket under the rail, "insert" heat set insert
    standoff_fastener = "tap"; // [tap, nut, insert]
    // heat set insert diameter
    insert_dia = 4.2; // [3:.1:6]
    // heat set insert depth
    insert_depth = 5.1; // [3:.1:8]

    /* [Foot] */
    // foot diameter
    foot_dia = 22; // [14:1:40]
    // foot height
    foot_height = 12; // [6:1:30]

    /* [Joint] */
    // overlap length of the half lap splices
    lap_length = 30; // [20:1:50]
    // joint bolt clearance diameter, M3
    joint_bolt_dia = 3.4; // [2:.1:5]
    // hex nut across flats, M3
    nut_af = 5.6; // [4:.1:9]
    // hex nut pocket depth
    nut_depth = 3; // [2:.1:6]

    /* [Hidden] */
    adj = 0.01;
    $fn = 60;

    board_x = 304.8;
    board_y = 330.2;
    board_t = 2;

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

    // longitudinal rail centre lines [name, x]
    long_cols = [["left", 6.35], ["right", 288.29]];
    // cross rail centre lines [name, y]
    cross_rows = [["rear", 10.16], ["middle", 165.10], ["front", 322.70]];

    // rails run slightly past the board outline so that the outermost standoff base
    // (right_front sits only 5.08 mm from the board edge) and every half lap are
    // fully backed by material
    rail_overhang = 2.5;
    long_y0  = -rail_overhang;
    long_y1  = board_y + rail_overhang;
    cross_x0 = -rail_overhang;
    cross_x1 = board_x + rail_overhang;

    // splice centres, chosen to clear every standoff and every rail crossing
    long_splice_y = 195;
    cross_splice_x = 120;

    // standoffs carried by the longitudinal rails [col, x, y]
    long_holes = [
        ["left",    6.35,  33.02],
        ["right", 288.29, 237.49]
    ];
    // standoffs carried by the cross rails [row, x, y]
    cross_holes = [
        ["rear",   163.83,  10.16],
        ["rear",   288.29,  10.16],
        ["middle",   6.35, 165.10],
        ["middle", 163.83, 165.10],
        ["middle", 288.29, 165.10],
        ["middle", 209.55, 187.96],
        ["front",    6.35, 322.58],
        ["front",  163.83, 322.88],
        ["front",  299.72, 322.58]
    ];

    // foot mount points along each longitudinal rail
    foot_y = [45, 300];

    // a rail crossing is "shared" when a board mounting hole lands on it, the board
    // screw then doubles as the joint bolt
    joint_tol = 10;
    function shared_hole(x, y) =
        [for(h = eeb_holes) if(abs(h[1]-x) < joint_tol && abs(h[2]-y) < joint_tol) h];
    function is_shared(x, y) = len(shared_hole(x, y)) > 0;
    // standoffs sitting on a crossing are always through bolted, never tapped
    function on_crossing(x, y) =
        len([for(c = long_cols) for(r = cross_rows)
            if(abs(c[1]-x) < joint_tol && abs(r[1]-y) < joint_tol) 1]) > 0;

    function standoff_hole_dia(x, y) =
        on_crossing(x, y) ? joint_bolt_dia :
            standoff_fastener == "nut" ? joint_bolt_dia :
                standoff_fastener == "insert" ? joint_bolt_dia : 2.6;
    function standoff_insert(x, y) =
        standoff_fastener == "insert" && !on_crossing(x, y);

    // bed footprint across the width of a cross segment, the middle right segment
    // carries the outrigger and is therefore wider than the bare rail
    function cross_seg_w(row, seg) =
        (row == "middle" && seg == "right")
            ? 187.96 + rail_w/2 - (165.10 - rail_w/2) : rail_w;


/* a single standoff pillar sitting on top of a rail at z = rail_h */

module frame_standoff(x, y) {

    ins = standoff_insert(x, y);
    translate([x, y, rail_h])
        standoff(["custom", standoff_dia, standoff_height, standoff_hole_dia(x, y),
                  standoff_dia+3, 2, "none", "round", "none", false,
                  ins, insert_dia, insert_depth], [false, 10, 2, "default"]);
}


/* vertical clearance hole plus a hex nut pocket in the underside of the lower member */

module bolt_and_nut(x, y, dia = 0) {

    d = dia == 0 ? joint_bolt_dia : dia;
    translate([x, y, -foot_height-10])
        cylinder(d=d, h=foot_height+rail_h+standoff_height+20);
    if(d > 3) {
        translate([x, y, -adj])
            rotate([0,0,30]) cylinder(d=nut_af*2/sqrt(3), h=nut_depth, $fn=6);
    }
}


/* every bolt hole in the frame, differenced from both rail families so the two
   members of a joint always line up */

module frame_fastener_holes() {

    // rail crossings that carry no board screw need a dedicated bolt
    for(c = long_cols) {
        for(r = cross_rows) {
            if(!is_shared(c[1], r[1])) {
                bolt_and_nut(c[1], r[1]);
            }
        }
    }
    // longitudinal splices, two bolts flanking the splice centre
    for(c = long_cols) {
        bolt_and_nut(c[1], long_splice_y - lap_length/2 + 7);
        bolt_and_nut(c[1], long_splice_y + lap_length/2 - 7);
    }
    // cross splices, two bolts flanking the splice centre
    for(r = cross_rows) {
        bolt_and_nut(cross_splice_x - lap_length/2 + 7, r[1]);
        bolt_and_nut(cross_splice_x + lap_length/2 - 7, r[1]);
    }
    // board screws that land on a crossing pass through both members
    for(c = long_cols) {
        for(r = cross_rows) {
            if(is_shared(c[1], r[1])) {
                bolt_and_nut(shared_hole(c[1], r[1])[0][1], shared_hole(c[1], r[1])[0][2]);
            }
        }
    }
}


/* full length longitudinal rail, lower member at every crossing */

module long_rail_full(col) {

    cx = [for(c = long_cols) if(c[0] == col) c[1]][0];

    difference() {
        union() {
            translate([cx-rail_w/2, long_y0, 0]) cube([rail_w, long_y1-long_y0, rail_h]);
            for(h = long_holes) if(h[0] == col) frame_standoff(h[1], h[2]);
        }
        // half lap, top half removed where a cross rail passes over
        for(r = cross_rows) {
            translate([cx-rail_w/2-adj, r[1]-rail_w/2, rail_h/2])
                cube([rail_w+2*adj, rail_w, rail_h/2+adj]);
        }
        // board screw holes for the standoffs this rail carries
        for(h = long_holes) if(h[0] == col) {
            translate([h[1], h[2], -adj]) cylinder(d=standoff_hole_dia(h[1], h[2]), h=rail_h+2*adj);
            if(standoff_hole_dia(h[1], h[2]) > 3) {
                translate([h[1], h[2], -adj]) rotate([0,0,30])
                    cylinder(d=nut_af*2/sqrt(3), h=nut_depth, $fn=6);
            }
        }
        // blind tap holes for the feet
        for(fy = foot_y) translate([cx, fy, -adj]) cylinder(d=2.6, h=6);
        frame_fastener_holes();
    }
}


/* full length cross rail, upper member at every crossing */

module cross_rail_full(row) {

    cy = [for(r = cross_rows) if(r[0] == row) r[1]][0];

    difference() {
        union() {
            translate([cross_x0, cy-rail_w/2, 0]) cube([cross_x1-cross_x0, rail_w, rail_h]);
            // outrigger to the orphan standoff behind the middle rail
            if(row == "middle") {
                translate([209.55-rail_w/2, cy, 0])
                    cube([rail_w, 187.96-cy+rail_w/2, rail_h]);
            }
            for(h = cross_holes) if(h[0] == row) frame_standoff(h[1], h[2]);
        }
        // half lap, bottom half removed where it crosses a longitudinal rail
        for(c = long_cols) {
            translate([c[1]-rail_w/2, cy-rail_w/2-adj, -adj])
                cube([rail_w, rail_w+2*adj, rail_h/2+adj]);
        }
        // board screw holes for the standoffs this rail carries
        for(h = cross_holes) if(h[0] == row) {
            translate([h[1], h[2], -adj]) cylinder(d=standoff_hole_dia(h[1], h[2]), h=rail_h+2*adj);
            if(standoff_hole_dia(h[1], h[2]) > 3 && !on_crossing(h[1], h[2])) {
                translate([h[1], h[2], -adj]) rotate([0,0,30])
                    cylinder(d=nut_af*2/sqrt(3), h=nut_depth, $fn=6);
            }
        }
        frame_fastener_holes();
    }
}


/* longitudinal rail cut into a printable segment, seg is "rear" or "front" */

module long_rail_seg(col, seg) {

    cx = [for(c = long_cols) if(c[0] == col) c[1]][0];
    lap0 = long_splice_y - lap_length/2;
    lap1 = long_splice_y + lap_length/2;

    intersection() {
        difference() {
            long_rail_full(col);
            // splice half lap, rear segment keeps the bottom, front segment the top
            if(seg == "rear") {
                translate([cx-rail_w/2-adj, lap0, rail_h/2])
                    cube([rail_w+2*adj, lap_length, rail_h/2+adj]);
            }
            else {
                translate([cx-rail_w/2-adj, lap0, -adj])
                    cube([rail_w+2*adj, lap_length, rail_h/2+adj]);
            }
        }
        if(seg == "rear") {
            translate([cx-60, long_y0-10, -foot_height-20]) cube([120, lap1-long_y0+10, 120]);
        }
        else {
            translate([cx-60, lap0, -foot_height-20]) cube([120, long_y1-lap0+10, 120]);
        }
    }
}


/* cross rail cut into a printable segment, seg is "left" or "right" */

module cross_rail_seg(row, seg) {

    cy = [for(r = cross_rows) if(r[0] == row) r[1]][0];
    lap0 = cross_splice_x - lap_length/2;
    lap1 = cross_splice_x + lap_length/2;

    intersection() {
        difference() {
            cross_rail_full(row);
            // splice half lap, left segment keeps the bottom, right segment the top
            if(seg == "left") {
                translate([lap0, cy-rail_w/2-adj, rail_h/2])
                    cube([lap_length, rail_w+2*adj, rail_h/2+adj]);
            }
            else {
                translate([lap0, cy-rail_w/2-adj, -adj])
                    cube([lap_length, rail_w+2*adj, rail_h/2+adj]);
            }
        }
        if(seg == "left") {
            translate([cross_x0-10, cy-60, -foot_height-20]) cube([lap1-cross_x0+10, 160, 120]);
        }
        else {
            translate([lap0, cy-60, -foot_height-20]) cube([cross_x1-lap0+10, 160, 120]);
        }
    }
}


/* bolt on foot */

module frame_foot() {

    difference() {
        union() {
            cylinder(d=foot_dia, h=foot_height-1);
            translate([0,0,foot_height-1]) cylinder(d1=foot_dia, d2=foot_dia-2, h=1);
        }
        translate([0,0,-adj]) cylinder(d=joint_bolt_dia, h=foot_height+2*adj);
        translate([0,0,-adj]) cylinder(d1=joint_bolt_dia*2.2, d2=joint_bolt_dia, h=joint_bolt_dia*.8);
    }
}


/* free standing standoff tower for the "pillars" build */

module pillar_tower() {

    tower_hole = standoff_fastener == "tap" ? 2.6 : joint_bolt_dia;

    difference() {
        union() {
            cylinder(d=foot_dia+14, h=3);
            translate([0,0,3]) cylinder(d1=foot_dia+14, d2=standoff_dia+4, h=foot_height);
            translate([0,0,3+foot_height]) cylinder(d=standoff_dia, h=standoff_height);
        }
        translate([0,0,-adj]) cylinder(d=tower_hole, h=foot_height+standoff_height+6);
        if(tower_hole > 3) {
            translate([0,0,-adj]) rotate([0,0,30]) cylinder(d=nut_af*2/sqrt(3), h=nut_depth, $fn=6);
        }
    }
}


/* reference motherboard */

module board_outline() {

    color("#1d5c3a", 0.35)
    difference() {
        translate([0,0,rail_h+standoff_height]) cube([board_x, board_y, board_t]);
        for(h = eeb_holes) translate([h[1], h[2], rail_h+standoff_height-1])
            cylinder(d=3.4, h=board_t+2);
    }
}


/* named part dispatch */

module named_part(p) {

    if(p == "long_left_rear")     long_rail_seg("left", "rear");
    if(p == "long_left_front")    long_rail_seg("left", "front");
    if(p == "long_right_rear")    long_rail_seg("right", "rear");
    if(p == "long_right_front")   long_rail_seg("right", "front");
    if(p == "cross_rear_left")    cross_rail_seg("rear", "left");
    if(p == "cross_rear_right")   cross_rail_seg("rear", "right");
    if(p == "cross_middle_left")  cross_rail_seg("middle", "left");
    if(p == "cross_middle_right") cross_rail_seg("middle", "right");
    if(p == "cross_front_left")   cross_rail_seg("front", "left");
    if(p == "cross_front_right")  cross_rail_seg("front", "right");
    if(p == "foot")               frame_foot();
    if(p == "pillar")             pillar_tower();
}


/* assembled frame */

module frame_model() {

    color("#4a90d9") {
        long_rail_seg("left", "rear");
        long_rail_seg("left", "front");
        long_rail_seg("right", "rear");
        long_rail_seg("right", "front");
    }
    color("#d98b4a") {
        cross_rail_seg("rear", "left");
        cross_rail_seg("rear", "right");
        cross_rail_seg("middle", "left");
        cross_rail_seg("middle", "right");
        cross_rail_seg("front", "left");
        cross_rail_seg("front", "right");
    }
    color("#777777")
    for(c = long_cols) for(fy = foot_y)
        translate([c[1], fy, -foot_height]) frame_foot();
}


/* place one longitudinal segment flat on the bed with its corner at the origin */

module place_long(col, seg) {

    cx = [for(c = long_cols) if(c[0] == col) c[1]][0];
    y0 = seg == "rear" ? long_y0 : long_splice_y - lap_length/2;
    translate([-(cx - rail_w/2), -y0, 0]) long_rail_seg(col, seg);
}


/* place one cross segment rotated so its length runs along y */

module place_cross(row, seg) {

    cy = [for(r = cross_rows) if(r[0] == row) r[1]][0];
    x0 = seg == "left" ? cross_x0 : cross_splice_x - lap_length/2;
    // move to the origin, turn 90 degrees, then bring back into positive x
    translate([cross_seg_w(row, seg), 0, 0])
        rotate([0,0,90])
            translate([-x0, -(cy - rail_w/2), 0])
                cross_rail_seg(row, seg);
}


/* print platter, every part laid flat in its print orientation.
   the whole set is wider than one bed, it is meant to be sliced in batches */

    // bed footprint of each platter part in the order they are placed
    platter_w = [rail_w, rail_w, rail_w, rail_w,
                 rail_w, rail_w,
                 rail_w, cross_seg_w("middle", "right"),
                 rail_w, rail_w];
    function platter_x(i) = i <= 0 ? 2 : platter_x(i-1) + platter_w[i-1] + platter_gap;

module frame_platter() {

    translate([platter_x(0), 2, 0]) place_long("left", "rear");
    translate([platter_x(1), 2, 0]) place_long("left", "front");
    translate([platter_x(2), 2, 0]) place_long("right", "rear");
    translate([platter_x(3), 2, 0]) place_long("right", "front");

    translate([platter_x(4), 2, 0]) place_cross("rear", "left");
    translate([platter_x(5), 2, 0]) place_cross("rear", "right");
    translate([platter_x(6), 2, 0]) place_cross("middle", "left");
    translate([platter_x(7), 2, 0]) place_cross("middle", "right");
    translate([platter_x(8), 2, 0]) place_cross("front", "left");
    translate([platter_x(9), 2, 0]) place_cross("front", "right");

    for(i = [0:3])
        translate([platter_x(10) + (foot_dia+platter_gap)*i, foot_dia/2+2, 0]) frame_foot();
}


/* main */

if(build == "pillars") {
    if(view == "model") {
        if(show_board) board_outline();
        for(h = eeb_holes) translate([h[1], h[2], 0]) pillar_tower();
    }
    else {
        cols = floor(bed_x / (foot_dia+14+platter_gap));
        for(i = [0:len(eeb_holes)-1])
            translate([(foot_dia+14+platter_gap)*(i%cols) + (foot_dia+14)/2 + 2,
                       (foot_dia+14+platter_gap)*floor(i/cols) + (foot_dia+14)/2 + 2, 0])
                pillar_tower();
    }
}
else {
    if(view == "model") {
        if(show_board) board_outline();
        frame_model();
    }
    if(view == "platter") frame_platter();
    if(view == "part") named_part(part);
}
