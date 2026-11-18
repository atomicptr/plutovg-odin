package plutovg

import "core:c"

IDENTITY_MATRIX :: Matrix{1, 0, 0, 0, 1, 0}
BLACK_COLOR :: Color{0, 0, 0, 1}
WHITE_COLOR :: Color{1, 1, 1, 1}
RED_COLOR :: Color{1, 0, 0, 1}
GREEN_COLOR :: Color{0, 1, 0, 1}
BLUE_COLOR :: Color{0, 0, 1, 1}
YELLOW_COLOR :: Color{1, 1, 0, 1}
CYAN_COLOR :: Color{0, 1, 1, 1}
MAGENTA_COLOR :: Color{1, 0, 1, 1}

// Encodes a version as major * 10000 + minor * 100 + micro, matching VERSION.
version_encode :: proc "contextless" (major, minor, micro: int) -> int {
	return major * 10000 + minor * 100 + micro
}

// Returns an affine matrix that scales coordinates by x and y.
make_scale :: proc "contextless" (x, y: f32) -> Matrix {return {x, 0, 0, 0, y, 0}}

// Returns an affine matrix that translates coordinates by x and y.
make_translate :: proc "contextless" (x, y: f32) -> Matrix {return {1, 0, x, 0, 1, y}}

// Parses an SVG transform string. The string overload returns the matrix and a success flag.
matrix_parse :: proc {
	matrix_parse_raw,
	matrix_parse_string,
}

// Transforms points from src into dst. The slice overload requires len(dst) >= len(src)
// and writes only the first len(src) destination points.
matrix_map_points :: proc {
	matrix_map_points_raw,
	matrix_map_points_slice,
}

// Appends SVG path data to path, returning true on success. Failure may leave a
// partially appended prefix. Use path_create_from_string for all-or-nothing creation.
path_parse :: proc {
	path_parse_raw,
	path_parse_string,
}

// Creates a copy of path with the given dash lengths and starting offset applied.
// Release the returned path with path_destroy.
path_clone_dashed :: proc {
	path_clone_dashed_raw,
	path_clone_dashed_slice,
}

// Parses CSS color syntax. The string overload returns the color and number of bytes
// consumed, including surrounding spaces; a consumed count of zero indicates failure.
color_parse :: proc {
	color_parse_raw,
	color_parse_string,
}

// Decodes encoded image bytes into a new surface, or returns nil on failure.
// Input storage is needed only during the call. Release the surface with surface_destroy.
surface_load_from_image_data :: proc {
	surface_load_from_image_data_raw,
	surface_load_from_image_slice,
}

// Decodes base64-encoded image data into a new surface, or returns nil on failure.
// Input storage is needed only during the call. Release the surface with surface_destroy.
surface_load_from_image_base64 :: proc {
	surface_load_from_image_base64_raw,
	surface_load_from_base64_string,
}

// Creates a surface backed by caller-owned native-endian premultiplied ARGB32 pixels.
// Keep the backing memory alive until the last surface reference is destroyed.
// Width and height are in pixels; stride is in bytes. The slice overload returns nil
// for invalid dimensions, insufficient storage, or storage not aligned for u32 pixels.
surface_create_for_data :: proc {
	surface_create_for_data_raw,
	surface_create_for_slice,
}

// Loads a font face from memory, or returns nil on failure.
// The slice overload borrows the bytes without installing a cleanup callback: keep
// them alive until the last face reference is destroyed, then free them yourself.
// ttcindex selects a face within a TrueType Collection and defaults to zero.
font_face_load_from_data :: proc {
	font_face_load_from_data_raw,
	font_face_load_borrowed,
}

// Creates a linear gradient from (x1, y1) to (x2, y2).
// The slice overload defaults to .Pad spread and no additional transform.
// Release the returned paint with paint_destroy.
paint_create_linear_gradient :: proc {
	paint_create_linear_gradient_raw,
	paint_create_linear_gradient_slice,
}

// Creates a radial gradient with center (cx, cy), radius cr, focal point (fx, fy),
// and focal radius fr. The slice overload defaults to .Pad and no extra transform.
// Release the returned paint with paint_destroy.
paint_create_radial_gradient :: proc {
	paint_create_radial_gradient_raw,
	paint_create_radial_gradient_slice,
}

// Sets dash lengths and the starting offset into the pattern. An empty slice
// selects a solid line. The initial canvas state has no dashes and zero offset.
canvas_set_dash :: proc {
	canvas_set_dash_raw,
	canvas_set_dash_slice,
}

// Fills text at (x, y), clears the current path, and returns the total advance width.
// The string overload interprets text as UTF-8.
canvas_fill_text :: proc {
	canvas_fill_text_raw,
	canvas_fill_text_string,
}

// Strokes text at (x, y), clears the current path, and returns the total advance width.
// The string overload interprets text as UTF-8.
canvas_stroke_text :: proc {
	canvas_stroke_text_raw,
	canvas_stroke_text_string,
}

// Intersects the clipping region with text at (x, y), clears the current path,
// and returns the total advance width. The string overload interprets text as UTF-8.
canvas_clip_text :: proc {
	canvas_clip_text_raw,
	canvas_clip_text_string,
}

// Adds text outlines to the current path at (x, y) and returns the total advance width.
// The string overload interprets text as UTF-8.
canvas_add_text :: proc {
	canvas_add_text_raw,
	canvas_add_text_string,
}

// Retrieves metrics for the current font. The value overload returns ascent,
// descent, line gap, and the font bounding box instead of taking output pointers.
canvas_font_metrics :: proc {
	canvas_font_metrics_raw,
	canvas_font_metrics_value,
}

// Retrieves glyph metrics for a Unicode codepoint. The value overload returns
// advance width, left side bearing, and the glyph bounding box.
canvas_glyph_metrics :: proc {
	canvas_glyph_metrics_raw,
	canvas_glyph_metrics_value,
}

@(private)
c_length :: proc "contextless" (length: int) -> c.int {
	assert_contextless(length >= 0 && length <= 0x7fff_ffff)
	return c.int(length)
}

@(private)
matrix_parse_string :: proc "contextless" (data: string) -> (transform: Matrix, ok: bool) {
	ok = matrix_parse_raw(&transform, cstring(raw_data(data)), c_length(len(data)))
	return
}

// Returns the inverse of transform and whether it is invertible.
// Use the returned matrix only when ok is true.
matrix_inverse :: proc "contextless" (transform: Matrix) -> (inverse: Matrix, ok: bool) {
	input := transform
	ok = matrix_invert(&input, &inverse)
	return
}

// Transforms (x, y) as a position, including the matrix's translation.
matrix_map_xy :: proc "contextless" (transform: Matrix, x, y: f32) -> (xx, yy: f32) {
	mapped := transform * [3]f32{x, y, 1}
	xx, yy = mapped[0, 0], mapped[1, 0]
	return
}

@(private)
matrix_map_points_slice :: proc "contextless" (transform: Matrix, src, dst: []Point) {
	assert_contextless(len(dst) >= len(src))
	input := transform
	matrix_map_points_raw(&input, raw_data(src), raw_data(dst), c_length(len(src)))
}

@(private)
path_parse_string :: proc "contextless" (path: ^Path, data: string) -> bool {
	return path_parse_raw(path, cstring(raw_data(data)), c_length(len(data)))
}

// Creates a path from SVG path data. Returns nil, false if allocation or parsing fails.
// Release a successfully created path with path_destroy.
path_create_from_string :: proc "contextless" (data: string) -> (path: ^Path, ok: bool) {
	path = path_create()
	if path == nil {return nil, false}
	if !path_parse_string(path, data) {
		path_destroy(path)
		return nil, false
	}
	return path, true
}

// Borrowed read-only view, invalidated by path mutation or destruction. Never free it.
path_elements :: proc "contextless" (path: ^Path) -> []Path_Element {
	data: [^]Path_Element
	count := path_get_elements(path, &data)
	return data[:int(count)]
}

// Returns the current path position: the last point added or moved to.
path_current_point :: proc "contextless" (path: ^Path) -> (x, y: f32) {
	path_get_current_point(path, &x, &y)
	return
}

// Returns path bounds and a length estimate. By default both use flattened curves.
// With tight = false, bounds include control points and length follows the control
// polygons rather than the curves.
path_bounds :: proc "contextless" (path: ^Path, tight := true) -> (bounds: Rect, length: f32) {
	length = path_extents(path, &bounds, tight)
	return
}

@(private)
path_clone_dashed_slice :: proc "contextless" (path: ^Path, offset: f32, dashes: []f32) -> ^Path {
	return path_clone_dashed_raw(path, offset, raw_data(dashes), c_length(len(dashes)))
}

// Creates a UTF-8 text iterator. It borrows text; keep the string alive and unchanged
// until iteration ends.
text_iterator_utf8 :: proc "contextless" (text: string) -> (it: Text_Iterator) {
	text_iterator_init(&it, raw_data(text), c_length(len(text)), .Utf8)
	return
}

@(private)
color_parse_string :: proc "contextless" (data: string) -> (color: Color, consumed: int) {
	consumed = int(color_parse_raw(&color, cstring(raw_data(data)), c_length(len(data))))
	return
}

@(private)
surface_load_from_image_slice :: proc "contextless" (data: []u8) -> ^Surface {
	return surface_load_from_image_data_raw(raw_data(data), c_length(len(data)))
}

@(private)
surface_load_from_base64_string :: proc "contextless" (data: string) -> ^Surface {
	return surface_load_from_image_base64_raw(cstring(raw_data(data)), c_length(len(data)))
}

@(private)
surface_create_for_slice :: proc "contextless" (
	data: []u8,
	width, height, stride: int,
) -> ^Surface {
	if width <= 0 || height <= 0 || stride <= 0 || stride % 4 != 0 {return nil}
	if width > 0x7fff_ffff / 4 || height > 0x7fff_ffff || stride > 0x7fff_ffff {return nil}
	if stride < width * 4 || height > len(data) / stride {return nil}
	if uintptr(raw_data(data)) % align_of(u32) != 0 {return nil}
	return surface_create_for_data_raw(raw_data(data), c.int(width), c.int(height), c.int(stride))
}

// Returns a borrowed writable byte view of the native-endian premultiplied ARGB32
// pixels, including row padding. Never free this slice. It is invalid after the last
// surface reference is destroyed or caller-owned backing storage ceases to exist.
surface_pixels :: proc "contextless" (surface: ^Surface) -> []u8 {
	length := int(surface_get_stride(surface)) * int(surface_get_height(surface))
	return surface_get_data(surface)[:length]
}

// Returns surface width and height in pixels and row stride in bytes.
surface_dimensions :: proc "contextless" (surface: ^Surface) -> (width, height, stride: int) {
	width = int(surface_get_width(surface))
	height = int(surface_get_height(surface))
	stride = int(surface_get_stride(surface))
	return
}

@(private)
font_face_load_borrowed :: proc "contextless" (data: []u8, ttcindex: c.int = 0) -> ^Font_Face {
	assert_contextless(len(data) <= 0xffff_ffff)
	return font_face_load_from_data_raw(raw_data(data), c.uint(len(data)), ttcindex, nil, nil)
}

@(private)
paint_create_linear_gradient_slice :: proc "contextless" (
	x1, y1, x2, y2: f32,
	stops: []Gradient_Stop,
	spread: Spread_Method = .Pad,
	transform: ^Matrix = nil,
) -> ^Paint {
	return paint_create_linear_gradient_raw(
		x1,
		y1,
		x2,
		y2,
		spread,
		raw_data(stops),
		c_length(len(stops)),
		transform,
	)
}

@(private)
paint_create_radial_gradient_slice :: proc "contextless" (
	cx, cy, cr, fx, fy, fr: f32,
	stops: []Gradient_Stop,
	spread: Spread_Method = .Pad,
	transform: ^Matrix = nil,
) -> ^Paint {
	return paint_create_radial_gradient_raw(
		cx,
		cy,
		cr,
		fx,
		fy,
		fr,
		spread,
		raw_data(stops),
		c_length(len(stops)),
		transform,
	)
}

@(private)
canvas_set_dash_slice :: proc "contextless" (canvas: ^Canvas, offset: f32, dashes: []f32) {
	canvas_set_dash_raw(canvas, offset, raw_data(dashes), c_length(len(dashes)))
}

// Borrowed read-only view, invalidated by dash/state changes or canvas destruction.
canvas_dashes :: proc "contextless" (canvas: ^Canvas) -> []f32 {
	data: [^]f32
	count := canvas_get_dash_array(canvas, &data)
	return data[:int(count)]
}

// Returns a copy of the canvas's current transformation matrix.
canvas_matrix :: proc "contextless" (canvas: ^Canvas) -> (transform: Matrix) {
	canvas_get_matrix(canvas, &transform)
	return
}

// Returns the last point added or moved to in the canvas's current path.
canvas_current_point :: proc "contextless" (canvas: ^Canvas) -> (x, y: f32) {
	canvas_get_current_point(canvas, &x, &y)
	return
}

// Maps a position through the canvas's current transformation matrix.
canvas_map_xy :: proc "contextless" (canvas: ^Canvas, x, y: f32) -> (xx, yy: f32) {
	canvas_map(canvas, x, y, &xx, &yy)
	return
}

// Returns the transformed fill bounds for the current path and fill rule.
// Clipping and surface dimensions are not considered.
canvas_fill_bounds :: proc "contextless" (canvas: ^Canvas) -> (bounds: Rect) {
	canvas_fill_extents(canvas, &bounds)
	return
}

// Returns the transformed stroke bounds for the current path and stroke style.
// Clipping and surface dimensions are not considered.
canvas_stroke_bounds :: proc "contextless" (canvas: ^Canvas) -> (bounds: Rect) {
	canvas_stroke_extents(canvas, &bounds)
	return
}

// Returns the bounds of the current clipping region, or the canvas area if no clip
// has been applied.
canvas_clip_bounds :: proc "contextless" (canvas: ^Canvas) -> (bounds: Rect) {
	canvas_clip_extents(canvas, &bounds)
	return
}

@(private)
canvas_fill_text_string :: proc "contextless" (canvas: ^Canvas, text: string, x, y: f32) -> f32 {
	return canvas_fill_text_raw(canvas, raw_data(text), c_length(len(text)), .Utf8, x, y)
}

@(private)
canvas_stroke_text_string :: proc "contextless" (canvas: ^Canvas, text: string, x, y: f32) -> f32 {
	return canvas_stroke_text_raw(canvas, raw_data(text), c_length(len(text)), .Utf8, x, y)
}

@(private)
canvas_clip_text_string :: proc "contextless" (canvas: ^Canvas, text: string, x, y: f32) -> f32 {
	return canvas_clip_text_raw(canvas, raw_data(text), c_length(len(text)), .Utf8, x, y)
}

@(private)
canvas_add_text_string :: proc "contextless" (canvas: ^Canvas, text: string, x, y: f32) -> f32 {
	return canvas_add_text_raw(canvas, raw_data(text), c_length(len(text)), .Utf8, x, y)
}

// Returns the bounding box and total advance width of UTF-8 text in the current font.
canvas_text_bounds :: proc "contextless" (
	canvas: ^Canvas,
	text: string,
) -> (
	bounds: Rect,
	advance: f32,
) {
	advance = canvas_text_extents(canvas, raw_data(text), c_length(len(text)), .Utf8, &bounds)
	return
}

@(private)
canvas_font_metrics_value :: proc "contextless" (
	canvas: ^Canvas,
) -> (
	ascent, descent, line_gap: f32,
	bounds: Rect,
) {
	canvas_font_metrics_raw(canvas, &ascent, &descent, &line_gap, &bounds)
	return
}

@(private)
canvas_glyph_metrics_value :: proc "contextless" (
	canvas: ^Canvas,
	codepoint: Codepoint,
) -> (
	advance, left_side_bearing: f32,
	bounds: Rect,
) {
	canvas_glyph_metrics_raw(canvas, codepoint, &advance, &left_side_bearing, &bounds)
	return
}

#assert(size_of(c.int) == 4 && size_of(c.uint) == 4 && size_of(c.float) == 4)
#assert(size_of(bool) == 1)
#assert(size_of(Point) == 8 && size_of(Rect) == 16 && size_of(Matrix) == 24)
#assert(size_of(Color) == 16 && size_of(Gradient_Stop) == 20)
#assert(size_of(Path_Command) == 4 && size_of(Path_Element) == 8)
#assert(size_of(Path_Iterator) == 16 && size_of(Text_Iterator) == 24)
#assert(align_of(Point) == align_of(f32))
// Stronger-than-C matrix alignment is safe: the C API only takes pointers
// to caller-owned matrices, never embedded or by-value matrices.
#assert(align_of(Matrix) >= align_of(f32) && align_of(Matrix) % align_of(f32) == 0)
#assert(align_of(Color) == align_of(f32))
#assert(align_of(Gradient_Stop) == align_of(f32))
#assert(offset_of(Gradient_Stop, offset) == 0 && offset_of(Gradient_Stop, color) == 4)
