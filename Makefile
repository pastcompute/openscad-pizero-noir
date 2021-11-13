all:;
	openscad -Dshow_camera=0 -Dparts=1 -o part1-lid.stl case.scad
	openscad -Dshow_camera=0 -Dparts=2 -o part2-enc.stl case.scad
	openscad -Dshow_camera=0 -Dparts=3 -o part3-visor.stl case.scad
	openscad -Dshow_camera=0 -Dparts=4 -o part4-clamp.stl case.scad

fix:;
	openscad-format -i case.scad -f