package draw_example

import vg "../../plutovg"
import "core:fmt"
import "core:math"
import "core:math/linalg"

main :: proc() {
	surface := vg.surface_create(320, 240)
	if surface == nil {
		fmt.eprintln("Could not allocate the drawing surface")
		return
	}
	defer vg.surface_destroy(surface)

	canvas := vg.canvas_create(surface)
	if canvas == nil {
		fmt.eprintln("Could not create the drawing canvas")
		return
	}
	defer vg.canvas_destroy(canvas)

	vg.canvas_set_rgb(canvas, 0.08, 0.10, 0.16)
	vg.canvas_fill_rect(canvas, 0, 0, 320, 240)

	ink := vg.Color{0.35, 0.75, 0.95, 1}
	vg.canvas_set_color(canvas, &ink)

	center := vg.Point{160, 120}
	rotation := linalg.matrix2_rotate(math.to_radians(f32(10)))
	offsets := [3]vg.Point{{0, -80}, {110, 70}, {-110, 70}}
	first := center + linalg.mul(rotation, offsets[0])

	vg.canvas_move_to(canvas, first.x, first.y)

	for offset in offsets[1:] {
		point := center + linalg.mul(rotation, offset)
		vg.canvas_line_to(canvas, point.x, point.y)
	}

	vg.canvas_close_path(canvas)
	vg.canvas_fill(canvas)

	if !vg.surface_write_to_png(surface, "draw.png") {
		fmt.eprintln("Could not write draw.png")
		return
	}

	fmt.println("Wrote draw.png")
}
