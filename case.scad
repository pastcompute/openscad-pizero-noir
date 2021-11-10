include <MCAD/units.scad>
include <MCAD/materials.scad>

// Size check from STL using https://raviriley.github.io/STL-to-OpenSCAD-Converter/
// - https://www.thingiverse.com/thing:3091624
// - https://www.thingiverse.com/thing:3816376 (printed as a test)
// - https://www.thingiverse.com/thing:2492880 - has a model of the camera
// Simple - https://www.instructables.com/Creating-a-custom-sized-box-for-3D-printing-with-O/
// https://forum.openscad.org/make-an-object-hollow-with-constant-wall-thickness-td14255.html


//openscad -Dshow_camera=0 -Dparts=1 -o part1-lid.stl case.scad
//openscad -Dshow_camera=0 -Dparts=2 -o part2-enc.stl case.scad


include <../openscad-openbuilds/utils/colors.scad>
include <./PI_IRCUT_CameraFromSTL.scad>
include <../smooth-prim/smooth_prim.scad>
include <../Round-Anything/polyround.scad>

show_camera = 0;
parts = 0;

w_wall = 2;

xw_case = 100; // width viewed from front, assuming front is where camera lense is
yh_case = 90; // height viewed from front
zd_case = 38;
r_case = 6;
visor_rw = 6;
visor_h = 10;
sr = 6; // radii of screw columns in corners

cam_y_offset = 30;   // 0 means lens is front middle; +ve gives more space to FPC cable
cam_z_offset = -1.5; // less negative == more protusion of camera out the front
cam_pcb_offset = -16.5 - cam_z_offset;
pi_cam_offset = 9;
pi_cam_strut_offset = 27.5;
cutout_offset = 20;
cutout_width = 32;

pir_radius = 23.0 / 2.0;

//x=1; // Wall thickness 
//difference(){ 
//cube([50,50,100], center=true); 
//cube([50-x,50-x,101], center=true); 
//}

module cam_at_position() {
translate([xw_case / 2.0, yh_case / 2.0 + cam_y_offset, zd_case + cam_z_offset])
object1();
}

// Points: x,y,bend amount?
function sunvisorPoints() = [[0.5,0,3],[visor_rw,visor_h,20],[xw_case-visor_rw,visor_h,20],[xw_case-0.5,0,3]];
rp=sunvisorPoints();
// offset == "thickness" each side of line, smoothness of curve
module visor() {
  translate([0,-2,0])
  polygon(polyRound(beamChain(rp,offset1=2,offset2=-2),17));
  
}

module column1() {
  // translate([0, 0, 0]) cylinder(zd_case, sr, sr);
  SmoothXYCube([2*sr, 2*sr, zd_case], 4);
}

module enclosure_core() {
  union() {
    difference() {
      SmoothXYCube([xw_case, yh_case, zd_case], r_case);
      translate([w_wall,w_wall,-1])
      SmoothXYCube([xw_case - 2 * w_wall, yh_case - 2 * w_wall, zd_case + 2], r_case);
      
      // cut out for USB cabling
      translate([cutout_offset, -0.01 + yh_case - w_wall, -0.20 + 3])
      cube([cutout_width, w_wall+0.2, 5 + 0.2 + 3]);
    }

    translate([0, 0, 0])
    column1();
    translate([xw_case - 2 * sr, 0, 0])
    column1();
    translate([xw_case - 2 * sr, yh_case - 2 * sr, 0])
    column1();
    translate([0, yh_case - 2 * sr, 0])
    column1();
  }
}

module enclosure() {
  enclosure_core();
  // struts
  translate([pi_cam_strut_offset, 0, -cam_pcb_offset])
  cube([4, yh_case, zd_case + cam_pcb_offset - pi_cam_offset]);
  translate([xw_case - pi_cam_strut_offset - w_wall*2, 0, -cam_pcb_offset])
  cube([4, yh_case, zd_case + cam_pcb_offset - pi_cam_offset]);
}

module front_lid() {
// case front lid
union() {
difference() {
translate([0,0,zd_case])
SmoothXYCube([xw_case, yh_case, w_wall], r_case);
cam_at_position();
translate([xw_case / 2 - 1, pir_radius + 10 ,zd_case - 0.1])
cylinder(w_wall + 0.2, pir_radius, pir_radius);

// hole for PIR sensor
}
// sun lense on front
translate([0,yh_case - visor_h,zd_case])
linear_extrude(height=18)
visor();


}
// TODO: screw holes
}

//show_camera = 1;
parts = 1;

if (show_camera == 1) {
  color(color_aluminum) cam_at_position();
}

if (parts == 0 || parts == 1) {
  color([0,0,1,0.65])
  front_lid();
}
if (parts == 0 || parts == 2) {
  color([1.0,0,0])
  enclosure();
}
