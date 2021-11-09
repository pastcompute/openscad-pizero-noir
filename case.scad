include <MCAD/units.scad>
include <MCAD/materials.scad>

// Size check from STL using https://raviriley.github.io/STL-to-OpenSCAD-Converter/
// - https://www.thingiverse.com/thing:3091624
// - https://www.thingiverse.com/thing:3816376 (printed as a test)
// - https://www.thingiverse.com/thing:2492880 - has a model of the camera
// Simple - https://www.instructables.com/Creating-a-custom-sized-box-for-3D-printing-with-O/
// https://forum.openscad.org/make-an-object-hollow-with-constant-wall-thickness-td14255.html


include <../openscad-openbuilds/utils/colors.scad>
include <./PI_IRCUT_CameraFromSTL.scad>
include <../smooth-prim/smooth_prim.scad>
include <../Round-Anything/polyround.scad>

w_wall = 2;

xw_case = 100; // width viewed from front, assuming front is where camera lense is
yh_case = 60; // height viewed from front
zd_case = 36;
r_case = 6;
visor_rw = 6;
visor_h = 10;

cam_y_offset = 6;   // 0 means lens is front middle; +ve gives more space to FPC cable
cam_z_offset = -1.5; // less negative == more protusion of camera out the front

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
polygon(polyRound(beamChain(rp,offset1=1,offset2=-1),20));
}

// case body
color([1.0,0,0])
difference() {
  SmoothXYCube([xw_case, yh_case, zd_case], r_case);
  translate([w_wall,w_wall,-1])
  SmoothXYCube([xw_case - 2 * w_wall, yh_case - 2 * w_wall, zd_case + 2], r_case);
}

// case front lid
color([0,0,1,0.65])
union() {
difference() {
translate([0,0,zd_case])
SmoothXYCube([xw_case, yh_case, w_wall], r_case);
cam_at_position();
}
// sun lense on front
translate([0,yh_case - visor_h,zd_case])
linear_extrude(height=15)
visor();
}
// TODO: screw holes



color(color_aluminum) cam_at_position();
