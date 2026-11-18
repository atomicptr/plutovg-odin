// Bindings for PlutoSVG v0.0.8: https://github.com/sammycage/plutosvg
package plutosvg

import vg "../plutovg"
import "core:c"

VERSION_MAJOR :: 0
VERSION_MINOR :: 0
VERSION_MICRO :: 8
VERSION :: VERSION_MAJOR * 10000 + VERSION_MINOR * 100 + VERSION_MICRO
VERSION_STRING :: "0.0.8"

when ODIN_ARCH != .amd64 && ODIN_ARCH != .arm64 {
	#panic("PlutoSVG requires amd64 or arm64")
}

when ODIN_OS == .Linux {
	when ODIN_ARCH == .amd64 {
		foreign import lib "lib/linux_amd64/libplutosvg.a"
	} else {
		foreign import lib "lib/linux_arm64/libplutosvg.a"
	}
} else when ODIN_OS == .Darwin {
	when ODIN_ARCH != .arm64 {
		#panic("plutosvg macOS imports require arm64")
	}
	foreign import lib "lib/darwin_arm64/libplutosvg.a"
} else when ODIN_OS == .Windows {
	when ODIN_ARCH != .amd64 {
		#panic("plutosvg Windows imports require amd64")
	}
	foreign import lib "lib/windows_amd64/plutosvg.lib"
} else {
	#panic("PlutoSVG supports Linux, macOS and Windows")
}

Document :: struct {
	_opaque: [0]u8,
}

Palette_Func :: #type proc "c" (
	closure: rawptr,
	name: [^]u8,
	length: c.int,
	color: ^vg.Color,
) -> bool

@(default_calling_convention = "c", link_prefix = "plutosvg_")
foreign lib {
	version :: proc() -> c.int ---
	version_string :: proc() -> cstring ---

	// The data and closure must remain valid until the document is destroyed.
	document_load_from_data :: proc(data: [^]u8, length: c.int, width: f32 = -1, height: f32 = -1, destroy_func: vg.Destroy_Func = nil, closure: rawptr = nil) -> ^Document ---
	document_load_from_file :: proc(filename: cstring, width: f32 = -1, height: f32 = -1) -> ^Document ---
	document_render :: proc(document: ^Document, id: cstring, canvas: ^vg.Canvas, current_color: ^vg.Color = nil, palette_func: Palette_Func = nil, closure: rawptr = nil) -> bool ---
	// The returned surface is owned by the caller; release it with vg.surface_destroy.
	document_render_to_surface :: proc(document: ^Document, id: cstring = nil, width: c.int = -1, height: c.int = -1, current_color: ^vg.Color = nil, palette_func: Palette_Func = nil, closure: rawptr = nil) -> ^vg.Surface ---
	document_get_width :: proc(document: ^Document) -> f32 ---
	document_get_height :: proc(document: ^Document) -> f32 ---
	@(link_name = "plutosvg_document_extents")
	document_extents_raw :: proc(document: ^Document, id: cstring, extents: ^vg.Rect) -> bool ---
	document_destroy :: proc(document: ^Document) ---
	// Nil unless built with FreeType integration.
	ft_svg_hooks :: proc() -> rawptr ---
}

// Both overloads borrow their input until document_destroy; neither copies it.
document_load :: proc {
	document_load_bytes,
	document_load_string,
}

@(private, require_results)
document_load_bytes :: proc "contextless" (
	data: []u8,
	width: f32 = -1,
	height: f32 = -1,
) -> ^Document {
	if len(data) == 0 || len(data) > 0x7fff_ffff {
		return nil
	}

	return document_load_from_data(raw_data(data), c.int(len(data)), width, height)
}

@(private, require_results)
document_load_string :: proc "contextless" (
	data: string,
	width: f32 = -1,
	height: f32 = -1,
) -> ^Document {
	return document_load_bytes(transmute([]u8)data, width, height)
}

@(require_results)
document_extents :: proc "contextless" (
	document: ^Document,
	id: cstring = nil,
) -> (
	extents: vg.Rect,
	ok: bool,
) {
	ok = document_extents_raw(document, id, &extents)
	return
}
