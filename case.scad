include <MCAD/materials.scad>
include <MCAD/units.scad>

show_camera = 0;
show_pi = 0;
parts = 0;

// Size check from STL using
// https://raviriley.github.io/STL-to-OpenSCAD-Converter/
// - https://www.thingiverse.com/thing:3091624
// - https://www.thingiverse.com/thing:3816376 (printed as a test)
// - https://www.thingiverse.com/thing:2492880 - has a model of the camera
// Simple -
// https://www.instructables.com/Creating-a-custom-sized-box-for-3D-printing-with-O/
// https://forum.openscad.org/make-an-object-hollow-with-constant-wall-thickness-td14255.html

// openscad -Dshow_camera=0 -Dparts=1 -o part1-lid.stl case.scad
// openscad -Dshow_camera=0 -Dparts=2 -o part2-enc.stl case.scad

include <../BOSL/constants.scad>
include <../BOSL/shapes.scad>
include <../Round-Anything/polyround.scad>
include <../openscad-openbuilds/utils/colors.scad>
include <../smooth-prim/smooth_prim.scad>
include <./PI_IRCUT_CameraFromSTL.scad>
include <../NopSCADlib/vitamins/pcb.scad>
include <../NopSCADlib/vitamins/pcbs.scad>

wall_thickness = 2;

xw_case = 100; // width viewed from front, assuming front is where camera lense is
yh_case = 80;  // height viewed from front
zd_case = 38;
r_case = 6;
visor_rw = 6;
visor_h = 10;
sr = 6; // radii of screw columns in corners

cam_y_offset_from_top = -24; // 0 means middle of lens would cut top of enclosure...
// -16 lines up as original, with original back ridges
cam_z_offset = -1.5; // less negative == more protusion of camera out the front
cam_pcb_offset = -16.5 - cam_z_offset;
pi_cam_offset = 9; // z
pi_cam_strut_offset = 27.5;
cutout_offset = 20;
cutout_width = 32;

pir_radius = 23.0 / 2.0;
pir_base_y = 10;
pir_mount_offset = -0.5;
pir_mount_w = 35;
pir_mount_ridge = 4.5;
pir_mount_ridge_wide = 6;
pir_mount_ridge_long_mid = 16;
pir_mount_ridge_high = 3.3;
pir_mount_h = 2;
pir_mount_d = 4;

// allow a bit of room for dovetails and screws
visor_offset = 4;
slot_size = 2;

irr = 3.4;
spotrr = 9.7;
spotxo = 27.1;
irxo = 16.1;

clampm_x = 5;
clampm_h = 2.5;
clamp_w = 6;
clamp_cr = 4;
clamp_holer = 1;
slot_l = 19;
clamp_holex = 8;
arc_sh = 1.8;
arc_sr = 0.9;

// inside diameter of PVC pipe, make this a snug fit and we will also taper it
pvcoutside = 69;
pvcinside = 62.2;
piped2 = pvcinside + 0.2;
taper_out = 0.5;
socket = 12;

// slot size. the receptacle will need some slack to deal with 3-d printing expansion
// otherwise the join is very very tight
piframe_slot_h = 3;
slot_slack = 0.2;


// x=1; // Wall thickness
// difference(){
// cube([50,50,100], center=true);
// cube([50-x,50-x,101], center=true);
// }

module bbox() {
  // https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Tips_and_Tricks#Computing_a_bounding_box
  // a 3D approx. of the children projection on X axis
  module xProjection() translate([ 0, 1 / 2, -1 / 2 ]) linear_extrude(1) hull() projection()
      rotate([ 90, 0, 0 ]) linear_extrude(1) projection() children();

  // a bounding box with an offset of 1 in all axis
  module bbx() minkowski() {
    xProjection() children(); // x axis
    rotate(-90)               // y axis
        xProjection() rotate(90) children();
    rotate([ 0, -90, 0 ]) // z axis
        xProjection() rotate([ 0, 90, 0 ]) children();
  }

  // offset children() (a cube) by -1 in all axis
  module shrink() intersection() {
    translate([ 1, 1, 1 ]) children();
    translate([ -1, -1, -1 ]) children();
  }

  shrink() bbx() children();
}

module cam_at_position() {
  translate([ xw_case / 2.0, yh_case + cam_y_offset_from_top, zd_case + cam_z_offset ]) { object1(); }
}

module cam_at_position2() {
  translate([ xw_case / 2.0, yh_case + cam_y_offset_from_top, zd_case + cam_z_offset ]) {

    camlense_r = 7.59;
    cylinder(15.6, camlense_r, camlense_r);

    translate([ -spotxo, 0, -5 ]) cylinder(15.6, spotrr, spotrr);
    translate([ -irxo, 6.9, -5 ]) cylinder(11.2, irr, irr, $fn = 20);
    translate([ spotxo, 0, -5 ]) cylinder(15.6, spotrr, spotrr);
    translate([ irxo, -6.9, -5 ]) cylinder(11.2, irr, irr, $fn = 20);
  }
}

// Points: x,y,bend amount?
function sunvisorPoints() = [
  [ 0.5, 0, 3 ], [ visor_rw, visor_h, 20 ], [ xw_case - visor_rw, visor_h, 20 ], [ xw_case - 0.5, 0, 3 ]
];
rp = sunvisorPoints();
// offset == "thickness" each side of line, smoothness of curve
module visor() { translate([ 0, -2, 0 ]) polygon(polyRound(beamChain(rp, offset1 = 2, offset2 = -2), 17)); }

module column1(h = zd_case) {
  // translate([0, 0, 0]) cylinder(zd_case, sr, sr);
  SmoothXYCube([ 2 * sr, 2 * sr, h ], 4);
}

module enclosure_core(depth = zd_case, w = xw_case, h = yh_case, columns = true) {
  union() {
    difference() {
      SmoothXYCube([ w, h, depth ], r_case);
      translate([ wall_thickness, wall_thickness, -1 ])
          SmoothXYCube([ w - 2 * wall_thickness, h - 2 * wall_thickness, depth + 2 ], r_case);

      //      // cut out for USB cabling
      //      translate([ cutout_offset, -0.01 + h - wall_thickness, -0.20 + 3 ])
      //          cube([ cutout_width, wall_thickness + 0.2, 5 + 0.2 + 3 ]);
    }

    if (columns) {
      translate([ 0, 0, 0 ]) column1(depth);
      translate([ w - 2 * sr, 0, 0 ]) column1(depth);
      translate([ w - 2 * sr, h - 2 * sr, 0 ]) column1(depth);
      translate([ 0, h - 2 * sr, 0 ]) column1(depth);
    }
  }
}

module enclosure() {
  enclosure_core();

  // struts
  translate([ pi_cam_strut_offset, 0, -cam_pcb_offset ])
      cube([ 4, yh_case, zd_case + cam_pcb_offset - pi_cam_offset ]);
  translate([ xw_case - pi_cam_strut_offset - wall_thickness * 2, 0, -cam_pcb_offset ])
      cube([ 4, yh_case, zd_case + cam_pcb_offset - pi_cam_offset ]);
}

// FIXME: move the lid to 0,0,0 then translate after
module front_lid() {
  // case front lid

  difference() {
    union() {
      difference() {
        union() {
          translate([ 0, 0, zd_case ]) SmoothXYCube([ xw_case, yh_case, wall_thickness ], r_case);
          translate([ 0, 0, zd_case ]) column1(wall_thickness);
          translate([ xw_case - 2 * sr, 0, zd_case ]) column1(wall_thickness);
          translate([ xw_case - 2 * sr, yh_case - 2 * sr, zd_case ]) column1(wall_thickness);
          translate([ 0, yh_case - 2 * sr, zd_case ]) column1(wall_thickness);
        }
        cam_at_position2();

        // hole for PIR sensor
        translate([ xw_case / 2 - 1, pir_radius + pir_base_y, zd_case - 0.1 ])
            cylinder(wall_thickness + 0.2, pir_radius, pir_radius);

        // corner drill holes
        drinset = 4;
        drr = 1.94;
        translate([ drinset, drinset, zd_case - 0.1 ]) cylinder(wall_thickness + 0.2, drr, drr, $fn = 20);
        translate([ xw_case - drinset, drinset, zd_case - 0.1 ])
            cylinder(wall_thickness + 0.2, drr, drr, $fn = 20);
        translate([ xw_case - drinset, yh_case - drinset, zd_case - 0.1 ])
            cylinder(wall_thickness + 0.2, drr, drr, $fn = 20);
        translate([ drinset, yh_case - drinset, zd_case - 0.1 ])
            cylinder(wall_thickness + 0.2, drr, drr, $fn = 20);
      }
      // mounts on back

      // 3/4 supporting arc around the spots
      translate([ xw_case / 2.0, yh_case + cam_y_offset_from_top, zd_case ]) {
        translate([ -spotxo, 0, -arc_sh ]) difference() {
          cylinder(arc_sh, spotrr + arc_sr, spotrr + arc_sr);
          translate([ 0, 0, -0.1 ]) cylinder(arc_sh + 0.2, spotrr, spotrr);
          translate([ 0, -spotrr + arc_sr, -arc_sh ]) cube([ spotrr + arc_sr, 1.8 * spotrr, spotrr ]);
        }
        translate([ spotxo, 0, -arc_sh ]) difference() {
          cylinder(arc_sh, spotrr + arc_sr, spotrr + arc_sr);
          translate([ 0, 0, -0.1 ]) cylinder(arc_sh + 0.2, spotrr, spotrr);
          rotate([ 0, 0, 180 ]) translate([ 0, -spotrr + arc_sr, -arc_sh ])
              cube([ spotrr + arc_sr, 1.8 * spotrr, spotrr ]);
        }
      }

      // PIR
      pir_xx = (xw_case - pir_mount_w - wall_thickness) / 2;
      translate([ pir_xx, pir_base_y - pir_mount_h + pir_mount_offset, zd_case - pir_mount_d ])
          cube([ pir_mount_w, pir_mount_h, pir_mount_d ]);
      // center the pir ridges, cap along the pir
      pir_ridge_lmax = (pir_radius * 2 - pir_mount_offset);
      if (pir_mount_ridge_long_mid > pir_ridge_lmax) {
        pir_mount_ridge_long_mid = pir_ridge_lmax;
      }
      pir_ridge_o = (pir_ridge_lmax - pir_mount_ridge_long_mid) / 2;
      pir2 = pir_base_y + pir_ridge_o + pir_mount_offset;
      translate([ pir_xx, pir2, zd_case - pir_mount_ridge_high ])
          cube([ pir_mount_ridge_wide, pir_mount_ridge_long_mid, pir_mount_ridge_high ]);
      translate([ pir_xx + pir_mount_w - pir_mount_ridge_wide, pir2, zd_case - pir_mount_ridge_high ])
          cube([ pir_mount_ridge_wide, pir_mount_ridge_long_mid, pir_mount_ridge_high ]);

      // support for the FFC connector to even out the camera itself
      ffc_w = 14;
      ffc_xx = (xw_case - ffc_w) / 2;
      ffc_yy = 13.5;
      ffc_h = 1;
      translate([ ffc_xx, yh_case + cam_y_offset_from_top - ffc_yy, zd_case - wall_thickness + ffc_h ])
          cube([ ffc_w, 3, ffc_h ]);

      // mounts for clamping the spotlights
      translate([ clampm_x, yh_case + cam_y_offset_from_top - wall_thickness + 1, zd_case - clampm_h ])
          difference() {
        cube([ clamp_w, clamp_w, clampm_h ]);
        translate([ clamp_w / 2, clamp_w / 2 ]) cylinder(clampm_h, 1, 1, true, $fn = 20);
      }
      translate([
        xw_case - clampm_x - clamp_w, yh_case + cam_y_offset_from_top - wall_thickness - 1, zd_case - clampm_h
      ]) difference() {
        cube([ clamp_w, clamp_w, clampm_h ]);
        translate([ clamp_w / 2, clamp_w / 2, 0 ]) cylinder(clampm_h, 1, 1, true, $fn = 20);
      }
    }
    // visor slots
    translate([ 24, yh_case - visor_offset - slot_size, zd_case - 0.1 ])
        cube([ 8, slot_size, wall_thickness + 0.2 ]);
    translate([ xw_case - 24 - 8, yh_case - visor_offset - slot_size, zd_case - 0.1 ])
        cube([ 8, slot_size, wall_thickness + 0.2 ]);
    translate([ xw_case / 2 - 4, yh_case - visor_offset - slot_size, zd_case - 0.1 ])
        cube([ 8, slot_size, wall_thickness + 0.2 ]);
  }
}
module sunvisor() {
  // sun lense on front
  translate([ 0, yh_case - visor_h - visor_offset, zd_case + wall_thickness ]) linear_extrude(height = 18)
      visor();

  // visor slots
  translate([ 24, yh_case - visor_offset - slot_size, zd_case - 0.1 ])
      cube([ 8, slot_size, wall_thickness + 0.2 ]);
  translate([ xw_case - 24 - 8, yh_case - visor_offset - slot_size, zd_case - 0.1 ])
      cube([ 8, slot_size, wall_thickness + 0.2 ]);
  translate([ xw_case / 2 - 4, yh_case - visor_offset - slot_size, zd_case - 0.1 ])
      cube([ 8, slot_size, wall_thickness + 0.2 ]);
}

module clamp(h1 = 3) {
  difference() {
    slot(h = h1, l = slot_l, r = clamp_cr);
    translate([ -clamp_holex, 0, -h1 / 2 - 0.1 ]) cylinder(h1 + 0.2, clamp_holer, clamp_holer, $fn = 20);
  }
}

// Adaptor to 68mm PVC pipe

module adapt0(offs = 4) {
  piped = pvcoutside;
  pipedmeat = 2; // extra to tsop invalid 2-manifold joining the plug
  depth = 15;
  oo = depth;
  dx = 0.5;
  plugwall = 3;
  wx = wall_thickness + dx;
  translate([ 0, 0, -offs ]) union() {
    difference() {
      hull() {
        enclosure_core(offs, columns = false);
        translate([ xw_case / 2, yh_case / 2, -depth ]) cylinder(r = piped / 2, h = 5);
      }
      difference() {
        // inner hull to be subtracted from solid hull
        hull() {
          translate([ wx, wx, 0 ]) enclosure_core(offs + 0.1, xw_case - wx * 2, yh_case - wx * 2, columns = false);
          translate([ xw_case / 2, yh_case / 2, -depth - 0.1 ]) cylinder(r = piped2 / 2 - pipedmeat, h = 5);
        }
        // and we remove from that part to be subtracted,
        // an impression of the columns that extends through, so we can infill the corners neatly
        translate([ 0, 0, -offs - oo ]) column1(offs + oo);
        translate([ xw_case - 2 * sr, 0, -offs - oo ]) column1(offs + oo);
        translate([ xw_case - 2 * sr, yh_case - 2 * sr, -offs - oo ]) column1(offs + oo);
        translate([ 0, yh_case - 2 * sr, -offs - oo ]) column1(offs + oo);
      }
    }
    column1(offs);
    translate([ xw_case - 2 * sr, 0, 0 ]) column1(offs);
    translate([ xw_case - 2 * sr, yh_case - 2 * sr, 0 ]) column1(offs);
    translate([ 0, yh_case - 2 * sr, 0 ]) column1(offs);
    // "plug"
    difference() {
      translate([ xw_case / 2, yh_case / 2, -depth - socket ])
          cylinder(socket, piped2 / 2, piped2 / 2 + taper_out, $fn = 40);
      translate([ xw_case / 2, yh_case / 2, -depth - socket - 0.01 ])
          cylinder(socket + 0.02, piped2 / 2 - plugwall, piped2 / 2 - plugwall);

      // slots - to connect pi carrier to
      translate([0, yh_case/2 - 3/2, -depth - socket - 0.5 ])
      cube([xw_case, piframe_slot_h + slot_slack, 5]);
    }
  }
}

module endstop() {
  depth = 15;
  plugwall = 2;
  backingr = 84 / 2;
  glanser = 8;
  difference() {
    translate([ xw_case / 2, yh_case / 2, 0 ])
        cylinder(socket, piped2 / 2, piped2 / 2 + taper_out, $fn = 40);
    translate([ xw_case / 2, yh_case / 2, 0 ])
        cylinder(socket, piped2 / 2 - plugwall, piped2 / 2 - plugwall);
  }
  difference() {
    translate([ xw_case / 2, yh_case / 2, socket ])
      cylinder(3, backingr, backingr);
    translate([ xw_case / 2, yh_case / 2, socket ])
      cylinder(3, glanser, glanser);
  }
}

module adapt(offs = 4) { adapt0(offs); }

module enclosure2() {
  translate([ 0, 0, zd_case - 10 ]) enclosure_core(6);
  translate([ 0, 0, zd_case - 10 ]) adapt(2);
  //  hull() {
  //    translate([xw_case/2, yh_case/2,-60])
  //      cylinder(r=30,h=12);
  //  }
}

// pi starts with its center of gravity at 0,0,0 ...
// so lets turn it in the orientation we need, with the CSI towards us
// and move it back so the csi end is at 0
module orientpi() {
  // finally, rotate it to face our face
  rotate([-90,0,0]) {
    // 32.57 lines up the PCB
    // 29 centers the holes on the axis
    translate([0,32.57-3.57,0])
    rotate([0,0,-90])
    pcb(RPI0);
  }
}

module framec(barw, bart) {
  hh = 16;
  intersection() {
    difference() {
      cylinder(barw, pvcinside/2, pvcinside/2);
      translate([0,0,-0.1]) cylinder(barw + 0.2, pvcinside/2 - bart, pvcinside/2 - bart);
    }
    translate([-pvcinside/2, 0, 0]) cube([pvcinside, hh, barw]);
  }
}

// create a frame to snugly hold the pi inside the PVC pipe
module piframe() {
  barw = 7;
  bart = 3;
  plen = 64.5;
  pwid = 30;
  slot_d = 5;
  slot_w = 4;
  slot_h = piframe_slot_h;
  
  // cross bars to screw the pi to
  translate([0,bart/2,0])
  difference() {
    union() {
      translate([-pvcinside/2, -bart,-barw/2]) cube([pvcinside, bart, barw]);
      translate([-pvcinside/2, -bart,-plen + barw/2]) cube([pvcinside, bart, barw]);

      translate([pwid / 2 - 1, -bart, -plen + barw/2]) cube([barw, bart, plen]);
      translate([-pwid / 2, -bart, -plen + barw/2]) cube([barw, bart, plen]);
    }
    translate([11.5,+0.1,0]) rotate([90,0,0]) cylinder(bart + 0.2, 1, 1);
    translate([-11.5,+0.1,0]) rotate([90,0,0]) cylinder(bart + 0.2, 1, 1);
    translate([11.5,+0.1,-plen + barw + 0.5]) rotate([90,0,0]) cylinder(bart + 0.2, 1, 1);
    translate([-11.5,+0.1,-plen + barw + 0.5]) rotate([90,0,0]) cylinder(bart + 0.2, 1, 1);
  }
 
  // a circular thingy to fit in
  translate([0,0,-barw + barw/2])
  framec(barw, bart+2);

  translate([0,0,-plen + barw/2])
  framec(barw, bart+2);

  // tabs to connect to the slots in the adaptor enclosure
  translate([pvcinside/2 - slot_w, -bart/2, barw/2]) {
    cube([slot_w, slot_h, slot_d]);
    rotate([0,-90,0]) right_triangle([slot_d, slot_h, slot_d]);
  }
  translate([-pvcinside/2, -bart/2, barw/2]) {
    cube([slot_w, slot_h, slot_d]);
    translate([slot_w, 0, 0]) right_triangle([slot_d, slot_h, slot_d]);
  }
}

module pipeclamp() {
  id = pvcoutside;
  ir = id / 2;
  wt = 3;
  ht = 12;
  st = 14;
  cw = 1;
  join = 15;
  bt = 5;

  difference() {  
    cylinder(12, ir + wt, ir + wt, $fn = 30);
    translate([0, 0, -0.01]) cylinder(ht + 0.02, ir, ir, $fn = 30);
    // slice out a bit so it is not touching...
    translate([-cw/2,0,0])
    translate([0, ir - 1, -0.01]) cube([cw, bt, st]);
  }
  difference() {
    union() {
      translate([cw/2,ir,0]) cube([wt,join+wt,ht]);
      translate([-cw/2 - wt,ir,0]) cube([wt,join+wt,ht]);
    }
    translate([-wt-cw,ir + join/2+wt,ht/2])
      rotate([90,0,90]) cylinder(cw*2 + 2 * wt, 2, 2);
  }
}

//translate([xw_case / 2, 0, 0])
//rotate([0,-90,-90])

//orientpi();
//piframe();

//show_pi= 1;
//parts = 6;

if (show_pi == 1) {
  // color([.7,.7,.7,0.79]) cam_at_position();
  color([ .9, 0, 0, 0.79 ]) orientpi();
}

if (show_camera == 1) {
  // color([.7,.7,.7,0.79]) cam_at_position();
  color([ .9, 0, 0, 0.79 ]) cam_at_position2();
}

if (parts == 0 || parts == 1) {
  color([ 0, 0, 1, 0.65 ]) front_lid();
}
if (parts == 0 || parts == 2) {
  color([ 0.7, 0.7, 0.7, 0.9 ]) enclosure2();
}
if (parts == 0 || parts == 3) {
  color([ 1.0, 1.0, 0 ]) sunvisor();
}

if (parts == 0 || parts == 4) {
  color([ 1.0, 1.0, 1.0 ]) {
    translate([
      clampm_x + slot_l - clamp_holex, yh_case + cam_y_offset_from_top - wall_thickness + 1.5 + clampm_x / 2,
      zd_case - wall_thickness - clampm_h + 1 - 4
    ]) clamp();
  }
}

if (parts == 0 || parts == 5) {
  color([ 0, 1.0, 0 ]) translate([xw_case, 0, 0]) endstop();
}

if (parts == 0 || parts == 6) {
  color([ 0, 1.0, 0 ]) piframe();
}

if (parts == 0 || parts == 7) {
  color([ 0, 0.7, 0 ]) translate([0,0,-70]) pipeclamp();
}
