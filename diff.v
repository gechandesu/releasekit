module releasekit

import arrays.diff as difflib
import os

// diff returns true if strings differ and patch text string.
pub fn diff(a string, b string) (bool, string) {
	mut ctx := difflib.diff(a.split_into_lines(), b.split_into_lines())
	return ctx.changes.len != 0, ctx.generate_patch(colorful: false, block_header: true)
}

// diff_files returns true if files differ and patch text string.
pub fn diff_files(a string, b string) !(bool, string) {
	file_a := os.read_lines(a)!
	file_b := os.read_lines(b)!
	mut ctx := difflib.diff(file_a, file_b)
	return ctx.changes.len != 0, ctx.generate_patch(colorful: false, block_header: true)
}
