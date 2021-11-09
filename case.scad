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

//x=1; // Wall thickness 
//difference(){ 
//cube([50,50,100], center=true); 
//cube([50-x,50-x,101], center=true); 
//} 

//color(color_aluminum)
//object1();

//translate([-50, -30, 0]) {
difference() {
SmoothXYCube([100, 50, 18], 2)
SmoothXYCube([190, 40, 16], 2);
}

