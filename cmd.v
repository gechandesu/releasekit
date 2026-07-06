module releasekit

import arrays
import os

// has_cmd returns true if command *name* is available.
// Note: Use relative or absolute paths for executables located outside of PATH.
pub fn has_cmd(name string) bool {
	_ := path_of_executable(name) or { return false }
	return true
}

// ensure_cmd checks if the command *name* is available and exits if not.
// Note: Use relative or absolute paths for executables located outside of PATH.
@[noterurn]
pub fn ensure_cmd(name string) {
	if !has_cmd(name) {
		text :=
			pretty_error('command `${name}` is not installed or not in PATH, please install it first')
		print_and_exit(text, 1)
	}
}

// path_of_executable returns the absolute path of the executable file *name*.
// Note: Use relative or absolute paths for executables located outside of PATH.
pub fn path_of_executable(name string) !string {
	if name.is_blank() {
		return os.ExecutableNotFoundError{}
	}

	// Do not search executable in PATH if its name contains a slashes (as POSIX-shells does),
	// See PATH in: https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap08.html#tag_08_03

	if name.contains('/') {
		actual_path := os.abs_path(os.expand_tilde_to_home(os.norm_path(name)))
		if is_executable_file(actual_path) {
			return actual_path
		} else {
			return os.ExecutableNotFoundError{}
		}
	}

	paths := os.getenv('PATH').split(os.path_delimiter)

	for path in paths {
		if path in ['', '.'] {
			// Prohibit current directory.
			continue
		}
		actual_path := os.abs_path(os.join_path_single(path, name))
		if is_executable_file(actual_path) {
			return actual_path
		}
	}

	return os.ExecutableNotFoundError{}
}

fn is_executable_file(file string) bool {
	return os.is_file(file) && os.is_executable(file)
}

// run_or_fail executes the command with arg arguments and fails if command returned non-zero exit-code.
pub fn run_or_fail(cmd string, arg ...string) ! {
	path := path_of_executable(cmd)!
	cmdline := arrays.append([path], arg).join(' ')
	mut process := os.new_process(path)
	process.set_args(arg)
	process.run()
	process.wait()
	if process.status != .exited && process.code != 0 {
		return error('run failed: ' + cmdline)
	}
}

pub struct CmdOutput {
pub:
	exit_code int
	stdout    string
	stderr    string
}

// run_capture_output executes the command with arg arguments and capture its output and exit-code.
pub fn run_capture_output(cmd string, arg ...string) !CmdOutput {
	path := path_of_executable(cmd)!
	mut process := os.new_process(path)
	process.set_redirect_stdio()
	process.set_args(arg)
	process.run()
	process.wait()
	return CmdOutput{
		exit_code: process.code
		stdout:    process.stdout_slurp()
		stderr:    process.stderr_slurp()
	}
}
