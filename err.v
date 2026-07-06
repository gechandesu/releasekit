module releasekit

import term

// pretty_error returns the colored (if available) error message with optional custom *prefix*.
pub fn pretty_error(msg string, prefix ?string) string {
	mut text := 'Error: ${msg}'
	if prefix != none {
		text = '${prefix}${msg}'
	}
	return term.fail_message(text)
}

// print_and_exit performs exit with *code* with *msg* printed to the stderr.
// This function is marked as @[noreturn] and can be used in `or {}` blocks.
@[noreturn]
pub fn print_and_exit(msg string, code int) {
	eprintln(msg)
	exit(code)
}
