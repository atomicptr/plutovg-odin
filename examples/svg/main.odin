package svg_example

import svg "../../plutosvg"
import vg "../../plutovg"
import "core:fmt"

main :: proc() {
	source :: #load("odin-logo.svg", string)

	document := svg.document_load(source, width = 320, height = 320)
	if document == nil {
		fmt.eprintln("Could not parse the SVG document")
		return
	}
	defer svg.document_destroy(document)

	surface := svg.document_render_to_surface(document)
	if surface == nil {
		fmt.eprintln("Could not render the SVG document")
		return
	}
	defer vg.surface_destroy(surface)

	if !vg.surface_write_to_png(surface, "svg.png") {
		fmt.eprintln("Could not write svg.png")
		return
	}

	fmt.println("Wrote svg.png")
}
