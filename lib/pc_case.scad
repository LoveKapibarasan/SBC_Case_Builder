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

*/


/*
           NAME: fan_blank
    DESCRIPTION: round blanking plate for an unused case fan opening. a slotted
                 ring fits the opening from outside and snaps behind the wall
           TODO: none

          USAGE: fan_blank(opening, wall, plate, thick, clearance)

                     opening = diameter of the fan opening in the case
                        wall = thickness of the case wall at the opening
                       plate = outer diameter of the cover plate
                       thick = plate thickness
                   clearance = radial clearance between ring and opening

                 printed plate down, ring up
*/

module fan_blank(opening=136, wall=3, plate=150, thick=2.4, clearance=.25) {

    ring_od = opening - 2*clearance;
    ring_w = 2;
    latch = 1;
    latch_h = 1.6;
    slots = 6;
    $fn = 180;
    adj = .01;

    difference() {
        union() {
            cylinder(d=plate, h=thick);
            // centring ring through the wall
            translate([0, 0, thick - adj]) difference() {
                cylinder(d=ring_od, h=wall + latch_h + adj);
                translate([0, 0, -1]) cylinder(d=ring_od - 2*ring_w, h=wall + latch_h + 2);
            }
            // snap latch, a 45 degree lip that springs over the inner face of the wall
            translate([0, 0, thick + wall]) difference() {
                cylinder(d1=ring_od + 2*latch, d2=ring_od, h=latch_h);
                translate([0, 0, -1]) cylinder(d=ring_od - 2*ring_w, h=latch_h + 2);
            }
        }
        // slots let the ring flex while the latch passes the wall
        for(i = [0:slots-1]) rotate([0, 0, i*360/slots])
            translate([ring_od/2 - ring_w - 1, -1.5, thick + 1])
                cube([ring_w + latch + 2, 3, wall + latch_h + 1]);
    }
}


/*
           NAME: pcie_slot_cover
    DESCRIPTION: blanking cover for an unused expansion slot opening, sized to the
                 case slot opening and bracket rail. the plate lies against the
                 inside of the rear wall, the tab rests on the rail and takes an
                 M3 screw
           TODO: none

          USAGE: pcie_slot_cover(width, height, thick, tab_depth, tab_thick, hole_x, hole_y, hole)

                       width = plate width
                      height = plate height up to the underside of the tab
                       thick = plate thickness
                   tab_depth = tab reach over the rail
                   tab_thick = tab thickness
                      hole_x = screw hole from the left edge of the plate
                      hole_y = screw hole from the wall side of the tab
                        hole = screw clearance hole

                 origin at the lower left of the wall side of the plate, the
                 plate is in xz, the tab points toward +y. printed plate down
*/

module pcie_slot_cover(width=19, height=109.5, thick=1.6, tab_depth=10, tab_thick=2,
                       hole_x=9.6, hole_y=5, hole=3.4) {

    $fn = 40;
    difference() {
        union() {
            cube([width, thick, height + tab_thick]);
            translate([0, 0, height]) cube([width, tab_depth, tab_thick]);
            // fillet between plate and tab so the tab does not snap off
            translate([0, thick, height]) rotate([0, 90, 0])
                linear_extrude(height = width) polygon([[0, 0], [3, 0], [0, 3]]);
        }
        translate([hole_x, hole_y, height - 1]) cylinder(d=hole, h=tab_thick + 2);
    }
}


/*
           NAME: hd_cage
    DESCRIPTION: cage for 3.5" or 2.5" drives standing on edge. each bay has a
                 divider on its low x side drilled with both the 3.5" and the 2.5"
                 bottom mounting pattern, so either size screws to it. the base
                 screws to the case floor with M3
           TODO: none

          USAGE: hd_cage(bays, wall, clearance, base)

                        bays = number of drive bays
                        wall = divider thickness
                   clearance = extra width per bay over a 26.1 mm 3.5" drive
                        base = base plate thickness

                 drives lie along y, stand in z, bays stack along x.
                 hd_cage_size(bays, wall, clearance, base) returns [x, y, z]
*/

function hd_cage_size(bays=4, wall=3, clearance=2, base=4) =
    [bays*(26.1 + clearance) + (bays + 1)*wall, 147, base + 101.6];

// base mounting holes in cage coordinates
function hd_cage_mounts(bays=4, wall=3, clearance=2, base=4) =
    let(s = hd_cage_size(bays, wall, clearance, base))
    [[wall + (26.1 + clearance)/2, 10], [wall + (26.1 + clearance)/2, s[1] - 10],
     [s[0] - wall - (26.1 + clearance)/2, 10], [s[0] - wall - (26.1 + clearance)/2, s[1] - 10]];

module hd_cage(bays=4, wall=3, clearance=2, base=4) {

    s = hd_cage_size(bays, wall, clearance, base);
    pitch = 26.1 + clearance + wall;
    adj = .01;
    $fn = 40;

    difference() {
        union() {
            // base with a large opening under each bay for airflow
            difference() {
                cube([s[0], s[1], base]);
                for(i = [0:bays-1])
                    translate([wall + i*pitch + 4, 22, -1]) cube([26.1 + clearance - 8, s[1] - 44, base + 2]);
            }
            // dividers and outer walls
            for(i = [0:bays]) translate([i*pitch, 0, 0]) cube([wall, s[1], s[2]]);
        }
        // drive mounting patterns on the divider on the low x side of every bay.
        // pattern x maps to cage z (drive width), pattern y to cage y (drive length)
        for(i = [0:bays-1]) {
            multmatrix([[0, 0, 1, i*pitch - adj], [0, 1, 0, 0], [1, 0, 0, base]])
                hd_holes(3.5, "portrait", "bottom", wall + 2*adj, "slot");
            multmatrix([[0, 0, 1, i*pitch - adj], [0, 1, 0, 0], [1, 0, 0, base]])
                hd_holes(2.5, "portrait", "bottom", wall + 2*adj, "slot");
        }
        // countersunk M3 base mounts
        for(m = hd_cage_mounts(bays, wall, clearance, base)) {
            translate([m[0], m[1], -1]) cylinder(d=3.4, h=base + 2);
            translate([m[0], m[1], base - 1.8]) cylinder(d1=3.4, d2=7, h=1.8 + adj);
        }
    }
}
