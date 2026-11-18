// PlutoVG 1.3.3 bindings. See deps/plutovg/include/plutovg.h.
package plutovg

import "core:c"

when ODIN_ARCH != .amd64 && ODIN_ARCH != .arm64 {
	#panic("PlutoVG requires amd64 or arm64")
}

when ODIN_OS == .Linux {
	when ODIN_ARCH == .amd64 {
		foreign import lib "lib/linux_amd64/libplutovg.a"
	} else {
		foreign import lib "lib/linux_arm64/libplutovg.a"
	}
	@(require) foreign import system_libraries {"system:c", "system:m", "system:pthread"}
} else when ODIN_OS == .Darwin {
	when ODIN_ARCH != .arm64 {
		#panic("plutovg macOS imports require arm64")
	}
	foreign import lib "lib/darwin_arm64/libplutovg.a"
	@(require) foreign import system_libraries "system:System"
} else when ODIN_OS == .Windows {
	when ODIN_ARCH != .amd64 {
		#panic("plutovg Windows imports require amd64")
	}
	foreign import lib "lib/windows_amd64/plutovg.lib"
} else {
	#panic("PlutoVG supports Linux, macOS and Windows")
}

VERSION_MAJOR :: 1
VERSION_MINOR :: 3
VERSION_MICRO :: 3
VERSION :: 10303
VERSION_STRING :: "1.3.3"

// A 2D point stored as [x, y].
Point :: [2]f32

// A 2D rectangle: (x, y) is the top-left corner; (w, h) is its width and height.
Rect :: struct {
	x, y, w, h: c.float,
}

// A 2D affine transformation in native column-major layout [a c e; b d f],
// with implicit final row [0 0 1].
Matrix :: matrix[2, 3]f32

// Straight (non-premultiplied) RGBA components [r, g, b, a], each in 0..1.
Color :: distinct [4]f32

// A gradient color stop; offset is in 0..1.
Gradient_Stop :: struct {
	offset: c.float,
	color:  Color,
}

// A reference-counted 2D drawing path; release references with path_destroy.
Path :: struct {
	_opaque: [0]u8,
}

// A reference-counted font face; release references with font_face_destroy.
Font_Face :: struct {
	_opaque: [0]u8,
}

// A reference-counted cache of loaded font faces, indexed by family and style.
Font_Face_Cache :: struct {
	_opaque: [0]u8,
}

// An image surface with native-endian 32-bit premultiplied ARGB pixels (0xAARRGGBB).
// RGB channels are multiplied by alpha and divided by 255.
Surface :: struct {
	_opaque: [0]u8,
}

// A reference-counted solid color, gradient, or texture used for drawing.
Paint :: struct {
	_opaque: [0]u8,
}

// A reference-counted drawing context targeting a Surface.
Canvas :: struct {
	_opaque: [0]u8,
}

// A path command header or coordinate point. header.length counts elements including the header.
// Move_To, Line_To, and Close headers are followed by one point; Cubic_To by three.
// Advance through the array by header.length, not by one element per command.
Path_Element :: struct #raw_union {
	header: struct {
		command: Path_Command,
		length:  c.int,
	},
	point:  Point,
}

// Traverses a path-owned element array; size is its element count and index the current position.
Path_Iterator :: struct {
	elements:    [^]Path_Element,
	size, index: c.int,
}

// Traverses code points in borrowed text. length and index count encoding code units,
// not Unicode code points; encoding describes the text representation.
Text_Iterator :: struct {
	text:     rawptr,
	length:   c.int,
	encoding: Text_Encoding,
	index:    c.int,
}

// A Unicode code point.
Codepoint :: c.uint

// Cleanup callback invoked with the supplied closure when its resource is no longer needed.
Destroy_Func :: #type proc "c" (closure: rawptr)

// Writes size bytes from data; closure is caller-supplied context.
Write_Func :: #type proc "c" (closure: rawptr, data: rawptr, size: c.int)

// Visits a path command and its npoints associated points; closure is caller-supplied context.
// The points are borrowed for the duration of the callback.
Path_Traverse_Func :: #type proc "c" (
	closure: rawptr,
	command: Path_Command,
	points: [^]Point,
	npoints: c.int,
)

// Commands stored in a path element stream.
Path_Command :: enum c.int {
	// Moves the current point without drawing.
	Move_To  = 0,
	// Draws a straight line to a point.
	Line_To  = 1,
	// Draws a cubic Bézier curve.
	Cubic_To = 2,
	// Closes the subpath with a line to its start.
	Close    = 3,
}

// Encodings used to decode text into Unicode code points.
Text_Encoding :: enum c.int {
	// Latin-1 bytes.
	Latin1 = 0,
	// UTF-8 code units (bytes).
	Utf8   = 1,
	// Native-endian UTF-16 code units.
	Utf16  = 2,
	// Native-endian UTF-32 code units.
	Utf32  = 3,
}

// Controls whether a texture is drawn once or tiled.
Texture_Type :: enum c.int {
	// Draws a single texture.
	Plain = 0,
	// Repeats the texture.
	Tiled = 1,
}

// Controls how gradients extend beyond their bounds.
Spread_Method :: enum c.int {
	// Extends the edge colors.
	Pad     = 0,
	// Reflects the gradient beyond its bounds.
	Reflect = 1,
	// Repeats the gradient pattern.
	Repeat  = 2,
}

// Determines which regions of a path are filled.
Fill_Rule :: enum c.int {
	// Non-zero winding rule.
	Non_Zero = 0,
	// Even-odd winding rule.
	Even_Odd = 1,
}

// Porter-Duff compositing operations on source and destination.
Operator :: enum c.int {
	// Clears the destination to transparent.
	Clear    = 0,
	// Source replaces destination.
	Src      = 1,
	// Keeps destination; ignores source.
	Dst      = 2,
	// Source over destination.
	Src_Over = 3,
	// Destination over source.
	Dst_Over = 4,
	// Source within destination.
	Src_In   = 5,
	// Destination within source.
	Dst_In   = 6,
	// Source outside destination.
	Src_Out  = 7,
	// Destination outside source.
	Dst_Out  = 8,
	// Source over destination, restricted to destination coverage.
	Src_Atop = 9,
	// Destination over source, restricted to source coverage.
	Dst_Atop = 10,
	// Combines non-overlapping source and destination regions.
	Xor      = 11,
}

// Shape at the ends of open stroked subpaths.
Line_Cap :: enum c.int {
	// Flat stroke ends.
	Butt   = 0,
	// Rounded stroke ends.
	Round  = 1,
	// Square stroke ends.
	Square = 2,
}

// Shape at the corners of stroked paths.
Line_Join :: enum c.int {
	// Sharp mitered corners.
	Miter = 0,
	// Rounded corners.
	Round = 1,
	// Flattened, beveled corners.
	Bevel = 2,
}

@(default_calling_convention = "c", link_prefix = "plutovg_")
foreign lib {

	// Returns the library version encoded as major * 10000 + minor * 100 + micro.
	version :: proc() -> c.int ---

	// Returns the library's zero-terminated version string.
	version_string :: proc() -> cstring ---

	// Initializes transform to [a c_ e; b d f], with implicit final row [0 0 1].
	matrix_init :: proc(transform: ^Matrix, a: c.float, b: c.float, c_: c.float, d: c.float, e: c.float, f: c.float) ---

	// Initializes a 2D transformation matrix to the identity matrix.
	matrix_init_identity :: proc(transform: ^Matrix) ---

	// Initializes transform to translation by offsets (tx, ty).
	matrix_init_translate :: proc(transform: ^Matrix, tx: c.float, ty: c.float) ---

	// Initializes transform to scaling by factors (sx, sy).
	matrix_init_scale :: proc(transform: ^Matrix, sx: c.float, sy: c.float) ---

	// Initializes transform to rotation by angle in radians.
	matrix_init_rotate :: proc(transform: ^Matrix, angle: c.float) ---

	// Initializes transform with shear angles shx and shy in radians; the off-diagonal entries are
	// their tangents.
	matrix_init_shear :: proc(transform: ^Matrix, shx: c.float, shy: c.float) ---

	// Adds a translation with offsets `tx` and `ty` to the matrix.
	matrix_translate :: proc(transform: ^Matrix, tx: c.float, ty: c.float) ---

	// Scales transform by factors sx and sy.
	matrix_scale :: proc(transform: ^Matrix, sx: c.float, sy: c.float) ---

	// Adds a rotation by angle in radians to transform.
	matrix_rotate :: proc(transform: ^Matrix, angle: c.float) ---

	// Adds shear angles shx and shy in radians to transform.
	matrix_shear :: proc(transform: ^Matrix, shx: c.float, shy: c.float) ---

	// Stores the composition of left followed by right in transform.
	// In homogeneous column-vector notation this is right * left, not left * right.
	// transform may alias either input.
	matrix_multiply :: proc(transform: ^Matrix, left: ^Matrix, right: ^Matrix) ---

	// Calculates the inverse of `transform` and stores it in `inverse`.
	// If `inverse` is `nil`, the function only checks if the matrix is invertible.
	// `transform` and `inverse` can be identical.
	// Returns `true` if the matrix is invertible; `false` otherwise.
	matrix_invert :: proc(transform: ^Matrix, inverse: ^Matrix) -> bool ---

	// Transforms the point `(x, y)` using `transform` and stores the result in `(xx, yy)`.
	matrix_map :: proc(transform: ^Matrix, x: c.float, y: c.float, xx: ^c.float, yy: ^c.float) ---

	// Transforms the `src` point using `transform` and stores the result in `dst`.
	// `src` and `dst` can be identical.
	matrix_map_point :: proc(transform: ^Matrix, src: ^Point, dst: ^Point) ---

	// Transforms count points from src into dst; the arrays may be identical.
	@(link_name = "plutovg_matrix_map_points")
	matrix_map_points_raw :: proc(transform: ^Matrix, src: [^]Point, dst: [^]Point, count: c.int) ---

	// Transforms src and stores its axis-aligned bounding rectangle in dst; src and dst may be
	// identical.
	matrix_map_rect :: proc(transform: ^Matrix, src: ^Rect, dst: ^Rect) ---

	// Parses an SVG transform string into a matrix.
	// length is the length of the string, or `-1` if zero-terminated.
	// Returns `true` on success, `false` on failure.
	@(link_name = "plutovg_matrix_parse")
	matrix_parse_raw :: proc(transform: ^Matrix, data: cstring, length: c.int) -> bool ---

	// Initializes a path iterator for a given path.
	path_iterator_init :: proc(it: ^Path_Iterator, path: ^Path) ---

	// Returns true if more path elements are available, false otherwise.
	path_iterator_has_next :: proc(it: ^Path_Iterator) -> bool ---

	// Returns the current command, writes its associated points, and advances the iterator.
	// points must have room for three Points. Call only while path_iterator_has_next returns true.
	path_iterator_next :: proc(it: ^Path_Iterator, points: [^]Point) -> Path_Command ---

	// Creates a new path object.
	// The caller owns the returned reference and must release it with path_destroy.
	path_create :: proc() -> ^Path ---

	// Increments the reference count and returns the same pointer; release with path_destroy.
	path_reference :: proc(path: ^Path) -> ^Path ---

	// Decrements the reference count and frees the object when it reaches zero.
	path_destroy :: proc(path: ^Path) ---

	// Retrieves the reference count of a path object.
	path_get_reference_count :: proc(path: ^Path) -> c.int ---

	// Returns the number of elements and sets elements to the path-owned element array.
	// Advance by each command header's length; the array is invalidated by path modification or
	// destruction.
	path_get_elements :: proc(path: ^Path, elements: ^[^]Path_Element) -> c.int ---

	// Starts a subpath at (x, y) without drawing a line (SVG M).
	path_move_to :: proc(path: ^Path, x: c.float, y: c.float) ---

	// Adds a straight line from the current point to (x, y) (SVG L).
	path_line_to :: proc(path: ^Path, x: c.float, y: c.float) ---

	// Adds a quadratic Bézier from the current point to (x2, y2), controlled by (x1, y1) (SVG Q).
	path_quad_to :: proc(path: ^Path, x1: c.float, y1: c.float, x2: c.float, y2: c.float) ---

	// Adds a cubic Bézier to (x3, y3), controlled by (x1, y1) and (x2, y2) (SVG C).
	path_cubic_to :: proc(path: ^Path, x1: c.float, y1: c.float, x2: c.float, y2: c.float, x3: c.float, y3: c.float) ---

	// Adds an elliptical arc from the current point to (x, y), with radii (rx, ry).
	// angle rotates the ellipse in radians. large_arc_flag selects the large rather than small arc;
	// sweep_flag selects the positive-angle rather than negative-angle direction (SVG A).
	path_arc_to :: proc(path: ^Path, rx: c.float, ry: c.float, angle: c.float, large_arc_flag: bool, sweep_flag: bool, x: c.float, y: c.float) ---

	// Closes the current subpath with a straight line to its starting point (SVG Z).
	path_close :: proc(path: ^Path) ---

	// Retrieves the current point of the path.
	path_get_current_point :: proc(path: ^Path, x: ^c.float, y: ^c.float) ---

	// Reserves space for count additional path elements to reduce future allocations.
	path_reserve :: proc(path: ^Path, count: c.int) ---

	// Clears all path data, resetting the path to its initial state.
	path_reset :: proc(path: ^Path) ---

	// Adds a rectangle with top-left corner (x, y) and dimensions (w, h).
	path_add_rect :: proc(path: ^Path, x: c.float, y: c.float, w: c.float, h: c.float) ---

	// Adds a rectangle at (x, y) with dimensions (w, h) and corner radii (rx, ry).
	path_add_round_rect :: proc(path: ^Path, x: c.float, y: c.float, w: c.float, h: c.float, rx: c.float, ry: c.float) ---

	// Adds an ellipse centered at (cx, cy) with radii (rx, ry).
	path_add_ellipse :: proc(path: ^Path, cx: c.float, cy: c.float, rx: c.float, ry: c.float) ---

	// Adds a circle centered at (cx, cy) with radius r.
	path_add_circle :: proc(path: ^Path, cx: c.float, cy: c.float, r: c.float) ---

	// Adds an arc centered at (cx, cy) with radius r, from a0 to a1 in radians.
	// ccw selects counter-clockwise (true) or clockwise (false).
	path_add_arc :: proc(path: ^Path, cx: c.float, cy: c.float, r: c.float, a0: c.float, a1: c.float, ccw: bool) ---

	// Appends all elements of source, optionally transformed by transform (nil for no transformation).
	path_add_path :: proc(path: ^Path, source: ^Path, transform: ^Matrix) ---

	// Applies a transformation matrix to the path.
	path_transform :: proc(path: ^Path, transform: ^Matrix) ---

	// Calls traverse_func for each path command, passing closure unchanged.
	path_traverse :: proc(path: ^Path, traverse_func: Path_Traverse_Func, closure: rawptr) ---

	// Calls traverse_func with closure for each command, flattening Bézier curves to line segments.
	path_traverse_flatten :: proc(path: ^Path, traverse_func: Path_Traverse_Func, closure: rawptr) ---

	// Traverses a dashed path, passing closure to traverse_func for each command.
	// dashes contains ndashes dash lengths; offset is the starting position in the pattern.
	path_traverse_dashed :: proc(path: ^Path, offset: c.float, dashes: [^]c.float, ndashes: c.int, traverse_func: Path_Traverse_Func, closure: rawptr) ---

	// Creates a copy of the path.
	// The caller owns the returned reference and must release it with path_destroy.
	path_clone :: proc(path: ^Path) -> ^Path ---

	// Creates a copy of the path with Bézier curves flattened to line segments.
	// The caller owns the returned reference and must release it with path_destroy.
	path_clone_flatten :: proc(path: ^Path) -> ^Path ---

	// Returns an owned copy of the path with the dash pattern applied; release with path_destroy.
	// dashes contains ndashes dash lengths; offset is the starting position in the pattern.
	@(link_name = "plutovg_path_clone_dashed")
	path_clone_dashed_raw :: proc(path: ^Path, offset: c.float, dashes: [^]c.float, ndashes: c.int) -> ^Path ---

	// Computes extents and returns a length estimate. With tight = true, both use
	// flattened curves. Otherwise bounds include control points and the returned length
	// follows the control polygons rather than the curves.
	path_extents :: proc(path: ^Path, extents: ^Rect, tight: bool) -> c.float ---

	// Returns the total path length estimated from flattened curves.
	path_length :: proc(path: ^Path) -> c.float ---

	// Appends SVG path data to path. Returns true on success; failure may leave a
	// partially appended prefix. Use path_create_from_string for all-or-nothing creation.
	// length is the number of bytes in data, or -1 for zero-terminated data.
	@(link_name = "plutovg_path_parse")
	path_parse_raw :: proc(path: ^Path, data: cstring, length: c.int) -> bool ---

	// Initializes a text iterator.
	// length counts encoding code units (bytes for Latin1/Utf8), or -1 for zero-terminated text.
	text_iterator_init :: proc(it: ^Text_Iterator, text: rawptr, length: c.int, encoding: Text_Encoding) ---

	// Returns true if more code points are available, false otherwise.
	text_iterator_has_next :: proc(it: ^Text_Iterator) -> bool ---

	// Returns the next code point and advances the iterator; call only while text_iterator_has_next is
	// true.
	text_iterator_next :: proc(it: ^Text_Iterator) -> Codepoint ---

	// Loads an owned font face from filename; returns nil on failure. Release with font_face_destroy.
	// ttcindex selects the face in a TrueType collection; use 0 for regular font files.
	font_face_load_from_file :: proc(filename: cstring, ttcindex: c.int) -> ^Font_Face ---

	// Loads a font face from length bytes without copying the data; returns nil on failure.
	// ttcindex selects the face in a TrueType collection (0 for a regular font).
	// Keep data alive until the face is destroyed. If non-nil, destroy_func(closure) is called
	// when the data is no longer needed, including on load failure.
	@(link_name = "plutovg_font_face_load_from_data")
	font_face_load_from_data_raw :: proc(data: rawptr, length: c.uint, ttcindex: c.int, destroy_func: Destroy_Func, closure: rawptr) -> ^Font_Face ---

	// Increments the reference count and returns the same pointer; release with font_face_destroy.
	font_face_reference :: proc(face: ^Font_Face) -> ^Font_Face ---

	// Decrements the reference count and frees the object when it reaches zero.
	font_face_destroy :: proc(face: ^Font_Face) ---

	// Retrieves the current reference count of a font face.
	font_face_get_reference_count :: proc(face: ^Font_Face) -> c.int ---

	// Writes the font ascent, descent, line gap, and bounding box at the given em size in pixels.
	// Any output pointer may be nil.
	font_face_get_metrics :: proc(face: ^Font_Face, size: c.float, ascent: ^c.float, descent: ^c.float, line_gap: ^c.float, extents: ^Rect) ---

	// Writes the glyph advance width, left side bearing, and bounding box at em size in pixels.
	// Any output pointer may be nil.
	font_face_get_glyph_metrics :: proc(face: ^Font_Face, size: c.float, codepoint: Codepoint, advance_width: ^c.float, left_side_bearing: ^c.float, extents: ^Rect) ---

	// Appends the glyph outline to path at origin (x, y), scaled to the given em size in pixels.
	// Returns its advance width.
	font_face_get_glyph_path :: proc(face: ^Font_Face, size: c.float, x: c.float, y: c.float, codepoint: Codepoint, path: ^Path) -> c.float ---

	// Traverses the glyph outline at origin (x, y), scaled to em size in pixels.
	// Passes closure to traverse_func for each command and returns the glyph advance width.
	font_face_traverse_glyph_path :: proc(face: ^Font_Face, size: c.float, x: c.float, y: c.float, codepoint: Codepoint, traverse_func: Path_Traverse_Func, closure: rawptr) -> c.float ---

	// Computes the bounding box of a text string and its advance width.
	// size is the font em size in pixels.
	// length counts encoding code units (bytes for Latin1/Utf8), or -1 for zero-terminated text.
	// Returns the total advance width of the text.
	font_face_text_extents :: proc(face: ^Font_Face, size: c.float, text: rawptr, length: c.int, encoding: Text_Encoding, extents: ^Rect) -> c.float ---

	// Create a new, empty font-face cache.
	// The caller owns the returned reference and must release it with font_face_cache_destroy.
	font_face_cache_create :: proc() -> ^Font_Face_Cache ---

	// Increments the reference count and returns the same pointer; release with
	// font_face_cache_destroy.
	font_face_cache_reference :: proc(cache: ^Font_Face_Cache) -> ^Font_Face_Cache ---

	// Decrements the reference count and frees the object when it reaches zero.
	font_face_cache_destroy :: proc(cache: ^Font_Face_Cache) ---

	// Retrieve the current reference count of a font-face cache.
	// Returns the current reference count, or 0 if cache is nil.
	font_face_cache_reference_count :: proc(cache: ^Font_Face_Cache) -> c.int ---

	// Remove all entries from a font-face cache.
	font_face_cache_reset :: proc(cache: ^Font_Face_Cache) ---

	// Add a font face to the cache with the specified family and style.
	font_face_cache_add :: proc(cache: ^Font_Face_Cache, family: cstring, bold: bool, italic: bool, face: ^Font_Face) ---

	// Load a font face from a file and add it to the cache with the specified family and style.
	// ttcindex is the index of the face in a TrueType collection (use 0 for non-TTC fonts).
	// Returns `true` on success, `false` if the file could not be loaded.
	font_face_cache_add_file :: proc(cache: ^Font_Face_Cache, family: cstring, bold: bool, italic: bool, filename: cstring, ttcindex: c.int) -> bool ---

	// Retrieve a font face from the cache by family and style.
	// Returns a pointer to the matching `Font_Face` object, or nil if not found. The returned face is
	// owned by the cache and must not be destroyed by the caller.
	font_face_cache_get :: proc(cache: ^Font_Face_Cache, family: cstring, bold: bool, italic: bool) -> ^Font_Face ---

	// Load all font faces from a file and add them to the cache.
	// Returns the number of faces successfully loaded, or `-1` if font face cache loading is disabled.
	font_face_cache_load_file :: proc(cache: ^Font_Face_Cache, filename: cstring) -> c.int ---

	// Load all font faces from files in a directory recursively and add them to the cache.
	// This scans the specified directory recursively and loads all supported font files.
	// Returns the number of faces successfully loaded, or `-1` if font face cache loading is disabled.
	font_face_cache_load_dir :: proc(cache: ^Font_Face_Cache, dirname: cstring) -> c.int ---

	// Load all available system font faces and add them to the cache.
	// This scans standard system font directories recursively and loads all supported font files.
	// Returns the number of faces successfully loaded, or `-1` if font face cache loading is disabled.
	font_face_cache_load_sys :: proc(cache: ^Font_Face_Cache) -> c.int ---

	// Initializes a color using RGB components in the 0-1 range.
	// Alpha is set to 1.
	color_init_rgb :: proc(color: ^Color, r: c.float, g: c.float, b: c.float) ---

	// Initializes a color using RGBA components in the 0-1 range.
	color_init_rgba :: proc(color: ^Color, r: c.float, g: c.float, b: c.float, a: c.float) ---

	// Initializes a color using RGB components in the 0-255 range.
	// Alpha is set to 1.
	color_init_rgb8 :: proc(color: ^Color, r: c.int, g: c.int, b: c.int) ---

	// Initializes a color using RGBA components in the 0-255 range.
	color_init_rgba8 :: proc(color: ^Color, r: c.int, g: c.int, b: c.int, a: c.int) ---

	// Initializes a color from a packed 0xRRGGBBAA value.
	color_init_rgba32 :: proc(color: ^Color, value: c.uint) ---

	// Initializes a color from a packed 0xAARRGGBB value.
	color_init_argb32 :: proc(color: ^Color, value: c.uint) ---

	// Initializes an HSL color: h is hue in degrees (0..360), s is saturation and l is lightness
	// (0..1).
	// Alpha is set to 1.
	color_init_hsl :: proc(color: ^Color, h: c.float, s: c.float, l: c.float) ---

	// Initializes an HSL color: h is hue in degrees (0..360), s is saturation and l is lightness
	// (0..1).
	// a is alpha in 0..1.
	color_init_hsla :: proc(color: ^Color, h: c.float, s: c.float, l: c.float, a: c.float) ---

	// Converts a color to a packed 0xRRGGBBAA value.
	color_to_rgba32 :: proc(color: ^Color) -> c.uint ---

	// Converts a color to a packed 0xAARRGGBB value.
	color_to_argb32 :: proc(color: ^Color) -> c.uint ---

	// Parses a color from a string using CSS color syntax.
	// length is the length of the input string in bytes, or `-1` if the string is zero-terminated.
	// Returns the number of characters consumed on success (including leading/trailing spaces), or 0
	// on failure.
	@(link_name = "plutovg_color_parse")
	color_parse_raw :: proc(color: ^Color, data: cstring, length: c.int) -> c.int ---

	// Creates a transparent surface with width and height in pixels.
	// Returns nil for invalid dimensions or allocation failure; release with surface_destroy.
	surface_create :: proc(width: c.int, height: c.int) -> ^Surface ---

	// Creates a surface over caller-owned native-endian premultiplied ARGB32 pixels.
	// width and height are in pixels; stride is bytes per row. Keep data alive for the surface's
	// lifetime.
	@(link_name = "plutovg_surface_create_for_data")
	surface_create_for_data_raw :: proc(data: [^]u8, width: c.int, height: c.int, stride: c.int) -> ^Surface ---

	// Loads an image surface from a file.
	// Returns pointer to the surface, or `nil` on failure.
	// The caller owns the result; release it with surface_destroy.
	surface_load_from_image_file :: proc(filename: cstring) -> ^Surface ---

	// Decodes length bytes of encoded image data into an owned surface, or returns nil on failure.
	// Release the returned reference with surface_destroy; data need not outlive the call.
	@(link_name = "plutovg_surface_load_from_image_data")
	surface_load_from_image_data_raw :: proc(data: rawptr, length: c.int) -> ^Surface ---

	// Loads an image surface from base64-encoded data.
	// length is the length of the data in bytes, or `-1` if zero-terminated.
	// Returns pointer to the surface, or `nil` on failure.
	// The caller owns the result; release it with surface_destroy.
	@(link_name = "plutovg_surface_load_from_image_base64")
	surface_load_from_image_base64_raw :: proc(data: cstring, length: c.int) -> ^Surface ---

	// Increments the reference count and returns the same pointer; release with surface_destroy.
	surface_reference :: proc(surface: ^Surface) -> ^Surface ---

	// Decrements the reference count and frees the object when it reaches zero.
	surface_destroy :: proc(surface: ^Surface) ---

	// Gets the current reference count of a surface.
	surface_get_reference_count :: proc(surface: ^Surface) -> c.int ---

	// Returns the surface-owned native-endian premultiplied ARGB32 pixel buffer.
	surface_get_data :: proc(surface: ^Surface) -> [^]u8 ---

	// Returns the surface width in pixels.
	surface_get_width :: proc(surface: ^Surface) -> c.int ---

	// Returns the surface height in pixels.
	surface_get_height :: proc(surface: ^Surface) -> c.int ---

	// Returns the number of bytes per pixel row.
	surface_get_stride :: proc(surface: ^Surface) -> c.int ---

	// Clears the entire surface with the specified color.
	surface_clear :: proc(surface: ^Surface, color: ^Color) ---

	// Writes the surface to a PNG file.
	// Returns `true` if successful, `false` otherwise.
	surface_write_to_png :: proc(surface: ^Surface, filename: cstring) -> bool ---

	// Writes the surface to a JPEG file.
	// quality is JPEG quality in 0..100.
	// Returns `true` if successful, `false` otherwise.
	surface_write_to_jpg :: proc(surface: ^Surface, filename: cstring, quality: c.int) -> bool ---

	// Writes the surface to a PNG stream.
	// closure is passed unchanged to the callback.
	// Returns `true` if successful, `false` otherwise.
	surface_write_to_png_stream :: proc(surface: ^Surface, write_func: Write_Func, closure: rawptr) -> bool ---

	// Writes the surface to a JPEG stream.
	// closure is passed unchanged to the callback.
	// quality is JPEG quality in 0..100.
	// Returns `true` if successful, `false` otherwise.
	surface_write_to_jpg_stream :: proc(surface: ^Surface, write_func: Write_Func, closure: rawptr, quality: c.int) -> bool ---

	// Converts native-endian premultiplied ARGB32 pixels to straight RGBA bytes.
	// width and height are pixels; stride is bytes per row in both buffers. src and dst may be
	// identical.
	convert_argb_to_rgba :: proc(dst: [^]u8, src: [^]u8, width: c.int, height: c.int, stride: c.int) ---

	// Converts straight RGBA bytes to native-endian premultiplied ARGB32 pixels.
	// width and height are pixels; stride is bytes per row in both buffers. src and dst may be
	// identical.
	convert_rgba_to_argb :: proc(dst: [^]u8, src: [^]u8, width: c.int, height: c.int, stride: c.int) ---

	// Creates an opaque solid RGB paint with components in 0..1; release with paint_destroy.
	paint_create_rgb :: proc(r: c.float, g: c.float, b: c.float) -> ^Paint ---

	// Creates a solid RGBA paint with components in 0..1; release with paint_destroy.
	paint_create_rgba :: proc(r: c.float, g: c.float, b: c.float, a: c.float) -> ^Paint ---

	// Creates a solid color paint.
	// The caller owns the returned reference and must release it with paint_destroy.
	paint_create_color :: proc(color: ^Color) -> ^Paint ---

	// Creates an owned linear gradient from (x1, y1) to (x2, y2).
	// Copies nstops gradient stops from stops; spread controls extension beyond the endpoints.
	// transform is optional (nil for identity). Release with paint_destroy.
	@(link_name = "plutovg_paint_create_linear_gradient")
	paint_create_linear_gradient_raw :: proc(x1: c.float, y1: c.float, x2: c.float, y2: c.float, spread: Spread_Method, stops: [^]Gradient_Stop, nstops: c.int, transform: ^Matrix) -> ^Paint ---

	// Creates an owned radial gradient with center (cx, cy), radius cr,
	// and focal center (fx, fy), radius fr. Copies nstops stops; spread controls extension.
	// transform is optional (nil for identity). Release with paint_destroy.
	@(link_name = "plutovg_paint_create_radial_gradient")
	paint_create_radial_gradient_raw :: proc(cx: c.float, cy: c.float, cr: c.float, fx: c.float, fy: c.float, fr: c.float, spread: Spread_Method, stops: [^]Gradient_Stop, nstops: c.int, transform: ^Matrix) -> ^Paint ---

	// Creates an owned texture paint, retaining a reference to surface.
	// opacity is in 0..1; type_ selects plain or tiled. transform is optional (nil for identity).
	// Release with paint_destroy.
	paint_create_texture :: proc(surface: ^Surface, type_: Texture_Type, opacity: c.float, transform: ^Matrix) -> ^Paint ---

	// Increments the reference count and returns the same pointer; release with paint_destroy.
	paint_reference :: proc(paint: ^Paint) -> ^Paint ---

	// Decrements the reference count and frees the object when it reaches zero.
	paint_destroy :: proc(paint: ^Paint) ---

	// Retrieves the reference count of a paint object.
	paint_get_reference_count :: proc(paint: ^Paint) -> c.int ---

	// Creates a drawing context on a surface.
	// The caller owns the returned reference and must release it with canvas_destroy.
	canvas_create :: proc(surface: ^Surface) -> ^Canvas ---

	// Increments the reference count and returns the same pointer; release with canvas_destroy.
	canvas_reference :: proc(canvas: ^Canvas) -> ^Canvas ---

	// Decrements the reference count and frees the object when it reaches zero.
	canvas_destroy :: proc(canvas: ^Canvas) ---

	// Retrieves the reference count of the canvas.
	canvas_get_reference_count :: proc(canvas: ^Canvas) -> c.int ---

	// Returns the borrowed drawing surface; take a surface_reference to retain it.
	canvas_get_surface :: proc(canvas: ^Canvas) -> ^Surface ---

	// Saves the current drawing state, including transformation and clip, but not the current path.
	canvas_save :: proc(canvas: ^Canvas) ---

	// Restores the most recently saved drawing state, without changing the current path.
	// Does nothing if there is no saved state.
	canvas_restore :: proc(canvas: ^Canvas) ---

	// Sets the current paint to opaque RGB with components in 0..1; the default is opaque black.
	canvas_set_rgb :: proc(canvas: ^Canvas, r: c.float, g: c.float, b: c.float) ---

	// Sets the current paint to RGBA with components in 0..1; the default is opaque black.
	canvas_set_rgba :: proc(canvas: ^Canvas, r: c.float, g: c.float, b: c.float, a: c.float) ---

	// Sets the current paint to a solid color.
	// If not set, the default paint is opaque black color.
	canvas_set_color :: proc(canvas: ^Canvas, color: ^Color) ---

	// Sets the current paint to a linear gradient from (x1, y1) to (x2, y2).
	// Copies nstops gradient stops from stops; spread controls extension beyond the endpoints.
	// transform is optional (nil for identity). The default paint is opaque black.
	canvas_set_linear_gradient :: proc(canvas: ^Canvas, x1: c.float, y1: c.float, x2: c.float, y2: c.float, spread: Spread_Method, stops: [^]Gradient_Stop, nstops: c.int, transform: ^Matrix) ---

	// Sets the current paint to a radial gradient with center (cx, cy), radius cr,
	// and focal center (fx, fy), radius fr. Copies nstops stops; spread controls extension.
	// transform is optional (nil for identity). The default paint is opaque black.
	canvas_set_radial_gradient :: proc(canvas: ^Canvas, cx: c.float, cy: c.float, cr: c.float, fx: c.float, fy: c.float, fr: c.float, spread: Spread_Method, stops: [^]Gradient_Stop, nstops: c.int, transform: ^Matrix) ---

	// Sets the current paint to a texture paint, retaining a reference to surface.
	// opacity is in 0..1; type_ selects plain or tiled. transform is optional (nil for identity). The
	// default paint is opaque black.
	canvas_set_texture :: proc(canvas: ^Canvas, surface: ^Surface, type_: Texture_Type, opacity: c.float, transform: ^Matrix) ---

	// Sets the current paint.
	// If not set, the default paint is opaque black color.
	canvas_set_paint :: proc(canvas: ^Canvas, paint: ^Paint) ---

	// Returns the borrowed current paint, or nil when a solid color is active.
	// If color is non-nil, copies the stored solid color into it. The default is opaque black.
	canvas_get_paint :: proc(canvas: ^Canvas, color: ^Color) -> ^Paint ---

	// Assigns a font-face cache to the canvas for font management.
	canvas_set_font_face_cache :: proc(canvas: ^Canvas, cache: ^Font_Face_Cache) ---

	// Returns the borrowed font-face cache, or nil if none is set.
	canvas_get_font_face_cache :: proc(canvas: ^Canvas) -> ^Font_Face_Cache ---

	// Add a font face to the canvas using the specified family and style.
	canvas_add_font_face :: proc(canvas: ^Canvas, family: cstring, bold: bool, italic: bool, face: ^Font_Face) ---

	// Load a font face from a file and add it to the canvas using the specified family and style.
	// ttcindex is the index within a TrueType Collection (use 0 for regular font files).
	// Returns `true` on success, or `false` if the font could not be loaded.
	canvas_add_font_file :: proc(canvas: ^Canvas, family: cstring, bold: bool, italic: bool, filename: cstring, ttcindex: c.int) -> bool ---

	// Selects and sets the current font face on the canvas.
	// Returns `true` if a matching font was found and set, `false` otherwise.
	canvas_select_font_face :: proc(canvas: ^Canvas, family: cstring, bold: bool, italic: bool) -> bool ---

	// Sets the font face and em size in pixels; defaults are nil and 12.
	canvas_set_font :: proc(canvas: ^Canvas, face: ^Font_Face, size: c.float) ---

	// Sets the font face for text rendering on the canvas.
	// If not set, the default font face is `nil`.
	canvas_set_font_face :: proc(canvas: ^Canvas, face: ^Font_Face) ---

	// Returns the borrowed current font face, or nil if none is set.
	canvas_get_font_face :: proc(canvas: ^Canvas) -> ^Font_Face ---

	// Sets the font em size in pixels; the default is 12.
	canvas_set_font_size :: proc(canvas: ^Canvas, size: c.float) ---

	// Returns the font em size in pixels; the default is 12.
	canvas_get_font_size :: proc(canvas: ^Canvas) -> c.float ---

	// Sets the fill rule.
	// If not set, the default fill rule is `.Non_Zero`.
	canvas_set_fill_rule :: proc(canvas: ^Canvas, winding: Fill_Rule) ---

	// Retrieves the current fill rule.
	// If not set, the default fill rule is `.Non_Zero`.
	canvas_get_fill_rule :: proc(canvas: ^Canvas) -> Fill_Rule ---

	// Sets the compositing operator.
	// If not set, the default compositing operator is `.Src_Over`.
	canvas_set_operator :: proc(canvas: ^Canvas, op: Operator) ---

	// Retrieves the current compositing operator.
	// If not set, the default compositing operator is `.Src_Over`.
	canvas_get_operator :: proc(canvas: ^Canvas) -> Operator ---

	// Sets the global opacity.
	// If not set, the default global opacity is 1.
	// opacity: The opacity value (0 to 1).
	canvas_set_opacity :: proc(canvas: ^Canvas, opacity: c.float) ---

	// Retrieves the current global opacity.
	// If not set, the default global opacity is 1.
	canvas_get_opacity :: proc(canvas: ^Canvas) -> c.float ---

	// Sets the line width.
	// If not set, the default line width is 1.
	canvas_set_line_width :: proc(canvas: ^Canvas, line_width: c.float) ---

	// Retrieves the current line width.
	// If not set, the default line width is 1.
	canvas_get_line_width :: proc(canvas: ^Canvas) -> c.float ---

	// Sets the line cap style.
	// If not set, the default line cap is `.Butt`.
	canvas_set_line_cap :: proc(canvas: ^Canvas, line_cap: Line_Cap) ---

	// Retrieves the current line cap style.
	// If not set, the default line cap is `.Butt`.
	canvas_get_line_cap :: proc(canvas: ^Canvas) -> Line_Cap ---

	// Sets the line join style.
	// If not set, the default line join is `.Miter`.
	canvas_set_line_join :: proc(canvas: ^Canvas, line_join: Line_Join) ---

	// Retrieves the current line join style.
	// If not set, the default line join is `.Miter`.
	canvas_get_line_join :: proc(canvas: ^Canvas) -> Line_Join ---

	// Sets the miter limit.
	// If not set, the default miter limit is 10.
	canvas_set_miter_limit :: proc(canvas: ^Canvas, miter_limit: c.float) ---

	// Retrieves the current miter limit.
	// If not set, the default miter limit is 10.
	canvas_get_miter_limit :: proc(canvas: ^Canvas) -> c.float ---

	// Copies ndashes dash lengths from dashes and sets the pattern offset.
	// Defaults to an empty pattern with offset 0.
	@(link_name = "plutovg_canvas_set_dash")
	canvas_set_dash_raw :: proc(canvas: ^Canvas, offset: c.float, dashes: [^]c.float, ndashes: c.int) ---

	// Sets the starting offset in the dash pattern; the default is 0.
	canvas_set_dash_offset :: proc(canvas: ^Canvas, offset: c.float) ---

	// Retrieves the current dash offset.
	// If not set, the default dash offset is 0.
	canvas_get_dash_offset :: proc(canvas: ^Canvas) -> c.float ---

	// Copies ndashes dash lengths from dashes; the default is an empty pattern.
	canvas_set_dash_array :: proc(canvas: ^Canvas, dashes: [^]c.float, ndashes: c.int) ---

	// Returns the number of dash lengths and sets dashes to the borrowed dash array.
	// The default is an empty pattern (nil).
	canvas_get_dash_array :: proc(canvas: ^Canvas, dashes: ^[^]c.float) -> c.int ---

	// Translates the current transformation matrix by offsets `tx` and `ty`.
	canvas_translate :: proc(canvas: ^Canvas, tx: c.float, ty: c.float) ---

	// Scales the current transformation matrix by factors `sx` and `sy`.
	canvas_scale :: proc(canvas: ^Canvas, sx: c.float, sy: c.float) ---

	// Adds shear angles shx and shy in radians to the current transformation.
	canvas_shear :: proc(canvas: ^Canvas, shx: c.float, shy: c.float) ---

	// Rotates the current transformation by angle in radians.
	canvas_rotate :: proc(canvas: ^Canvas, angle: c.float) ---

	// Multiplies the current transformation matrix with the specified `transform`.
	canvas_transform :: proc(canvas: ^Canvas, transform: ^Matrix) ---

	// Resets the current transformation matrix to the identity matrix.
	canvas_reset_matrix :: proc(canvas: ^Canvas) ---

	// Resets the current transformation matrix to the specified `transform`.
	canvas_set_matrix :: proc(canvas: ^Canvas, transform: ^Matrix) ---

	// Stores the current transformation matrix in `transform`.
	canvas_get_matrix :: proc(canvas: ^Canvas, transform: ^Matrix) ---

	// Maps (x, y) through the current transformation and writes the result to (xx, yy).
	canvas_map :: proc(canvas: ^Canvas, x: c.float, y: c.float, xx: ^c.float, yy: ^c.float) ---

	// Transforms the `src` point using the current transformation matrix and stores the result in
	// `dst`.
	// `src` and `dst` can be identical.
	canvas_map_point :: proc(canvas: ^Canvas, src: ^Point, dst: ^Point) ---

	// Maps src through the current transformation and writes its axis-aligned bounds to dst.
	// src and dst may be identical.
	canvas_map_rect :: proc(canvas: ^Canvas, src: ^Rect, dst: ^Rect) ---

	// Starts a subpath at (x, y) without drawing a line (SVG M).
	canvas_move_to :: proc(canvas: ^Canvas, x: c.float, y: c.float) ---

	// Adds a straight line from the current point to (x, y) (SVG L).
	canvas_line_to :: proc(canvas: ^Canvas, x: c.float, y: c.float) ---

	// Adds a quadratic Bézier from the current point to (x2, y2), controlled by (x1, y1) (SVG Q).
	canvas_quad_to :: proc(canvas: ^Canvas, x1: c.float, y1: c.float, x2: c.float, y2: c.float) ---

	// Adds a cubic Bézier to (x3, y3), controlled by (x1, y1) and (x2, y2) (SVG C).
	canvas_cubic_to :: proc(canvas: ^Canvas, x1: c.float, y1: c.float, x2: c.float, y2: c.float, x3: c.float, y3: c.float) ---

	// Adds an elliptical arc from the current point to (x, y), with radii (rx, ry).
	// angle rotates the ellipse in radians. large_arc_flag selects the large rather than small arc;
	// sweep_flag selects the positive-angle rather than negative-angle direction (SVG A).
	canvas_arc_to :: proc(canvas: ^Canvas, rx: c.float, ry: c.float, angle: c.float, large_arc_flag: bool, sweep_flag: bool, x: c.float, y: c.float) ---

	// Adds a rectangle with top-left corner (x, y) and dimensions (w, h).
	canvas_rect :: proc(canvas: ^Canvas, x: c.float, y: c.float, w: c.float, h: c.float) ---

	// Adds a rectangle at (x, y) with dimensions (w, h) and corner radii (rx, ry).
	canvas_round_rect :: proc(canvas: ^Canvas, x: c.float, y: c.float, w: c.float, h: c.float, rx: c.float, ry: c.float) ---

	// Adds an ellipse centered at (cx, cy) with radii (rx, ry).
	canvas_ellipse :: proc(canvas: ^Canvas, cx: c.float, cy: c.float, rx: c.float, ry: c.float) ---

	// Adds a circle centered at (cx, cy) with radius r.
	canvas_circle :: proc(canvas: ^Canvas, cx: c.float, cy: c.float, r: c.float) ---

	// Adds an arc centered at (cx, cy) with radius r, from a0 to a1 in radians.
	// ccw selects counter-clockwise (true) or clockwise (false).
	canvas_arc :: proc(canvas: ^Canvas, cx: c.float, cy: c.float, r: c.float, a0: c.float, a1: c.float, ccw: bool) ---

	// Adds a path to the current path.
	canvas_add_path :: proc(canvas: ^Canvas, path: ^Path) ---

	// Clears the current path and starts an empty one.
	canvas_new_path :: proc(canvas: ^Canvas) ---

	// Closes the current subpath with a straight line to its starting point (SVG Z).
	canvas_close_path :: proc(canvas: ^Canvas) ---

	// Retrieves the current point of the canvas.
	canvas_get_current_point :: proc(canvas: ^Canvas, x: ^c.float, y: ^c.float) ---

	// Returns the borrowed current path.
	canvas_get_path :: proc(canvas: ^Canvas) -> ^Path ---

	// Returns true if device-space (x, y) is in the rasterized fill of the transformed current path.
	// Uses the current fill rule, ignoring clipping and surface dimensions.
	canvas_fill_contains :: proc(canvas: ^Canvas, x: c.float, y: c.float) -> bool ---

	// Tests whether device-space (x, y) lies in the stroke region.
	// Upstream 1.3.3 currently rasterizes the fill instead, ignoring stroke settings; do not rely on
	// this function for stroke hit testing. Clipping and surface dimensions are ignored.
	canvas_stroke_contains :: proc(canvas: ^Canvas, x: c.float, y: c.float) -> bool ---

	// Returns true if device-space (x, y) lies within the current clip.
	// Without an explicit clip, tests the full canvas rectangle.
	canvas_clip_contains :: proc(canvas: ^Canvas, x: c.float, y: c.float) -> bool ---

	// Computes the axis-aligned rasterized fill bounds in device space using the current path,
	// fill rule, and transformation. Ignores clipping and surface dimensions.
	canvas_fill_extents :: proc(canvas: ^Canvas, extents: ^Rect) ---

	// Computes the axis-aligned rasterized stroke bounds in device space using the current path,
	// stroke settings, dash pattern, and transformation. Ignores clipping and surface dimensions.
	canvas_stroke_extents :: proc(canvas: ^Canvas, extents: ^Rect) ---

	// Gets the device-space axis-aligned bounds of the active clip.
	// Without an explicit clip, returns the full canvas rectangle.
	canvas_clip_extents :: proc(canvas: ^Canvas, extents: ^Rect) ---

	// A drawing operator that fills the current path according to the current fill rule.
	// The current path will be cleared after this operation.
	canvas_fill :: proc(canvas: ^Canvas) ---

	// A drawing operator that strokes the current path according to the current stroke settings.
	// The current path will be cleared after this operation.
	canvas_stroke :: proc(canvas: ^Canvas) ---

	// A drawing operator that intersects the current clipping region with the current path according
	// to the current fill rule.
	// The current path will be cleared after this operation.
	canvas_clip :: proc(canvas: ^Canvas) ---

	// A drawing operator that paints the current clipping region using the current paint.
	// The current path will not be affected by this operation.
	canvas_paint :: proc(canvas: ^Canvas) ---

	// A drawing operator that fills the current path according to the current fill rule.
	// The current path will be preserved after this operation.
	canvas_fill_preserve :: proc(canvas: ^Canvas) ---

	// A drawing operator that strokes the current path according to the current stroke settings.
	// The current path will be preserved after this operation.
	canvas_stroke_preserve :: proc(canvas: ^Canvas) ---

	// A drawing operator that intersects the current clipping region with the current path according
	// to the current fill rule.
	// The current path will be preserved after this operation.
	canvas_clip_preserve :: proc(canvas: ^Canvas) ---

	// Fills a rectangle according to the current fill rule.
	// The current path will be cleared by this operation.
	canvas_fill_rect :: proc(canvas: ^Canvas, x: c.float, y: c.float, w: c.float, h: c.float) ---

	// Fills a path according to the current fill rule.
	// The current path will be cleared by this operation.
	canvas_fill_path :: proc(canvas: ^Canvas, path: ^Path) ---

	// Strokes a rectangle with the current stroke settings.
	// The current path will be cleared by this operation.
	canvas_stroke_rect :: proc(canvas: ^Canvas, x: c.float, y: c.float, w: c.float, h: c.float) ---

	// Strokes a path with the current stroke settings.
	// The current path will be cleared by this operation.
	canvas_stroke_path :: proc(canvas: ^Canvas, path: ^Path) ---

	// Intersects the current clipping region with a rectangle according to the current fill rule.
	// The current path will be cleared by this operation.
	canvas_clip_rect :: proc(canvas: ^Canvas, x: c.float, y: c.float, w: c.float, h: c.float) ---

	// Intersects the current clipping region with a path according to the current fill rule.
	// The current path will be cleared by this operation.
	canvas_clip_path :: proc(canvas: ^Canvas, path: ^Path) ---

	// Adds a glyph to the current path at the specified origin.
	// Returns the advance width of the glyph.
	canvas_add_glyph :: proc(canvas: ^Canvas, codepoint: Codepoint, x: c.float, y: c.float) -> c.float ---

	// Adds text to the current path at the specified origin.
	// length counts encoding code units (bytes for Latin1/Utf8), or -1 for zero-terminated text.
	// Returns the total advance width of the text.
	@(link_name = "plutovg_canvas_add_text")
	canvas_add_text_raw :: proc(canvas: ^Canvas, text: rawptr, length: c.int, encoding: Text_Encoding, x: c.float, y: c.float) -> c.float ---

	// Fills text at the specified origin.
	// The current path will be cleared by this operation.
	// length counts encoding code units (bytes for Latin1/Utf8), or -1 for zero-terminated text.
	// Returns the total advance width of the text.
	@(link_name = "plutovg_canvas_fill_text")
	canvas_fill_text_raw :: proc(canvas: ^Canvas, text: rawptr, length: c.int, encoding: Text_Encoding, x: c.float, y: c.float) -> c.float ---

	// Strokes text at the specified origin.
	// The current path will be cleared by this operation.
	// length counts encoding code units (bytes for Latin1/Utf8), or -1 for zero-terminated text.
	// Returns the total advance width of the text.
	@(link_name = "plutovg_canvas_stroke_text")
	canvas_stroke_text_raw :: proc(canvas: ^Canvas, text: rawptr, length: c.int, encoding: Text_Encoding, x: c.float, y: c.float) -> c.float ---

	// Intersects the current clipping region with text at the specified origin.
	// The current path will be cleared by this operation.
	// length counts encoding code units (bytes for Latin1/Utf8), or -1 for zero-terminated text.
	// Returns the total advance width of the text.
	@(link_name = "plutovg_canvas_clip_text")
	canvas_clip_text_raw :: proc(canvas: ^Canvas, text: rawptr, length: c.int, encoding: Text_Encoding, x: c.float, y: c.float) -> c.float ---

	// Writes ascent, descent, line gap, and font bounds for the current font at its em size in pixels.
	@(link_name = "plutovg_canvas_font_metrics")
	canvas_font_metrics_raw :: proc(canvas: ^Canvas, ascent: ^c.float, descent: ^c.float, line_gap: ^c.float, extents: ^Rect) ---

	// Writes advance width, left side bearing, and glyph bounds for the current font at its em size in
	// pixels.
	@(link_name = "plutovg_canvas_glyph_metrics")
	canvas_glyph_metrics_raw :: proc(canvas: ^Canvas, codepoint: Codepoint, advance_width: ^c.float, left_side_bearing: ^c.float, extents: ^Rect) ---

	// Retrieves the extents of a text.
	// length counts encoding code units (bytes for Latin1/Utf8), or -1 for zero-terminated text.
	// Returns the total advance width of the text.
	canvas_text_extents :: proc(canvas: ^Canvas, text: rawptr, length: c.int, encoding: Text_Encoding, extents: ^Rect) -> c.float ---
}
