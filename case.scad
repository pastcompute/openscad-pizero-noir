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

wall_thickness = 2;

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
pir_base_y = 10;
pir_mount_offset = -0.5;
pir_mount_w = 35;
pir_mount_ridge = 4.5;
pir_mount_ridge_wide = 6;
pir_mount_ridge_high = 3.3;
pir_mount_h = 2;
pir_mount_d = 4;

//x=1; // Wall thickness 
//difference(){ 
//cube([50,50,100], center=true); 
//cube([50-x,50-x,101], center=true); 
//}

module bbox() { 
  // https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Tips_and_Tricks#Computing_a_bounding_box
    // a 3D approx. of the children projection on X axis 
    module xProjection() 
        translate([0,1/2,-1/2]) 
            linear_extrude(1) 
                hull() 
                    projection() 
                        rotate([90,0,0]) 
                            linear_extrude(1) 
                                projection() children(); 
  
    // a bounding box with an offset of 1 in all axis
    module bbx()  
        minkowski() { 
            xProjection() children(); // x axis
            rotate(-90)               // y axis
                xProjection() rotate(90) children(); 
            rotate([0,-90,0])         // z axis
                xProjection() rotate([0,90,0]) children(); 
        } 
    
    // offset children() (a cube) by -1 in all axis
    module shrink()
      intersection() {
        translate([ 1, 1, 1]) children();
        translate([-1,-1,-1]) children();
      }

   shrink() bbx() children(); 
}

module cam_at_position() {
translate([xw_case / 2.0, yh_case / 2.0 + cam_y_offset, zd_case + cam_z_offset]) {
  object1();
}
}

module cam_at_position2() {
translate([xw_case / 2.0, yh_case / 2.0 + cam_y_offset, zd_case + cam_z_offset]) {
  cylinder(15.6, 7.65,7.65);
  translate([-30.5,0,-5])
  cylinder(15.6, 9.49, 9.49);
  translate([30.5,0,-5])
  cylinder(15.6, 9.49, 9.49);
  
  translate([-19.5,6.9,-5])
  cylinder(11.2, 3,3,$fn=20);

  translate([19.5,-6.9,-5])
  cylinder(11.2, 3,3,$fn=20);

}
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
      translate([wall_thickness,wall_thickness,-1])
      SmoothXYCube([xw_case - 2 * wall_thickness, yh_case - 2 * wall_thickness, zd_case + 2], r_case);
      
      // cut out for USB cabling
      translate([cutout_offset, -0.01 + yh_case - wall_thickness, -0.20 + 3])
      cube([cutout_width, wall_thickness+0.2, 5 + 0.2 + 3]);
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
  translate([xw_case - pi_cam_strut_offset - wall_thickness*2, 0, -cam_pcb_offset])
  cube([4, yh_case, zd_case + cam_pcb_offset - pi_cam_offset]);
}

module front_lid() {
// case front lid
union() {
difference() {
translate([0,0,zd_case])
SmoothXYCube([xw_case, yh_case, wall_thickness], r_case);
cam_at_position2();

// hole for PIR sensor
translate([xw_case / 2 - 1, pir_radius + pir_base_y ,zd_case - 0.1])
cylinder(wall_thickness + 0.2, pir_radius, pir_radius);
}
// mounts on back
pir_xx = (xw_case - pir_mount_w - wall_thickness) / 2;
translate([pir_xx, pir_base_y - pir_mount_h + pir_mount_offset, zd_case - pir_mount_d])
cube([pir_mount_w, pir_mount_h, pir_mount_d]);

translate([pir_xx, pir_base_y + pir_mount_offset, zd_case - pir_mount_ridge_high])
cube([pir_mount_ridge_wide, pir_radius * 2 - pir_mount_offset, pir_mount_ridge_high]);
translate([pir_xx + pir_mount_w - pir_mount_ridge_wide, pir_base_y + pir_mount_offset, zd_case - pir_mount_ridge_high])
cube([pir_mount_ridge_wide, pir_radius * 2 - pir_mount_offset, pir_mount_ridge_high]);


// sun lense on front
translate([0,yh_case - visor_h,zd_case])
linear_extrude(height=18)
visor();


}
// TODO: screw holes
}

//show_camera = 1;
parts = 0;

//%bbox() cam_at_position();

if (show_camera == 1) {
  //color([.7,.7,.7,0.79]) cam_at_position();
  color([.9,0,0,0.79]) cam_at_position2();
}

if (parts == 0 || parts == 1) {
  color([0,0,1,0.65])
  front_lid();
}
if (parts == 0 || parts == 2) {
  color([1.0,0,0])
  enclosure();
}
