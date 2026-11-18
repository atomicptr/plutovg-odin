# plutovg-odin

Odin bindings for the standalone 2D vector graphics library [plutovg](https://github.com/sammycage/plutovg) and the SVG rendering library [plutosvg](https://github.com/sammycage/plutosvg).

## Basic usage

The examples below are adapted from the official repositories

### PlutoVG: draw a smiley

```odin
package main

import vg "plutovg"
import "core:fmt"
import "core:math"

main :: proc() {
	size :: 150

	surface := vg.surface_create(size, size)
	if surface == nil {
		fmt.eprintln("Could not create the drawing surface")
		return
	}
	defer vg.surface_destroy(surface)

	canvas := vg.canvas_create(surface)
	if canvas == nil {
		fmt.eprintln("Could not create the drawing canvas")
		return
	}
	defer vg.canvas_destroy(canvas)

	center := vg.Point{size / 2, size / 2}

	vg.canvas_circle(canvas, center.x, center.y, 70)
	vg.canvas_set_rgb(canvas, 1, 1, 0)
	vg.canvas_fill_preserve(canvas)
	vg.canvas_set_rgb(canvas, 0, 0, 0)
	vg.canvas_set_line_width(canvas, 5)
	vg.canvas_stroke(canvas)

	eye_offsets := [2]vg.Point{{-25, -20}, {25, -20}}
	for offset in eye_offsets {
		eye := center + offset
		vg.canvas_circle(canvas, eye.x, eye.y, 10)
	}
	vg.canvas_fill(canvas)

	vg.canvas_arc(canvas, center.x, center.y, 50, 0, math.PI, false)
	vg.canvas_stroke(canvas)

	if !vg.surface_write_to_png(surface, "smiley.png") {
		fmt.eprintln("Could not write smiley.png")
	}
}
```

### PlutoSVG: render an SVG to PNG

```odin
package main

import svg "plutosvg"
import vg "plutovg"
import "core:fmt"

main :: proc() {
	document := svg.document_load_from_file("camera.svg")
	if document == nil {
		fmt.eprintln("Could not load camera.svg")
		return
	}
	defer svg.document_destroy(document)

	surface := svg.document_render_to_surface(document)
	if surface == nil {
		fmt.eprintln("Could not render camera.svg")
		return
	}
	defer vg.surface_destroy(surface)

	if !vg.surface_write_to_png(surface, "camera.png") {
		fmt.eprintln("Could not write camera.png")
	}
}
```

## License

MIT
