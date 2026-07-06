module releasekit

import maps
import os

pub struct Build {
pub:
	name     string
	version  string
	os       string = os.user_os()
	arch     string = os.uname().machine
	work_dir string = '.'
	v        string = 'v'
	cc       string
	vflags   []string
	cflags   []string
	ldflags  []string
	env      map[string]string

	entrypoint        string = '.'
	output_dir        string = '.'
	output_file_name  string
	file_name_pattern string = '%n_%v_%o_%a'
}

// atrifact_name returns the name of the created file based on output_file_name
// and file_name_pattern. If output_file_name is not specified, the rules in
// file_name_pattern are used.
//
// | Placeholder | Meaning             | Source    |
// | ----------- | ------------------- | --------- |
// | %n          | program name        | `name`    |
// | %v          | program version     | `version` |
// | %o          | target OS           | `os`      |
// | %a          | target architecture | `arch`    |
//
// Note: If `os` is 'windows' the missing '.exe' extension will be added.
pub fn (build Build) artifact_name() string {
	name := if build.output_file_name != '' {
		build.output_file_name
	} else {
		build.file_name_pattern.replace_each([
			'%n',
			build.name,
			'%v',
			build.version,
			'%o',
			build.os,
			'%a',
			build.arch,
		])
	}
	if build.os.to_lower() == 'windows' && !name.to_lower().ends_with('.exe') {
		return name + '.exe'
	}
	return name
}

// artifact_path returns the absolute path to the produced artifact.
pub fn (build Build) artifact_path() string {
	return os.join_path_single(os.abs_path(build.output_dir), build.artifact_name())
}

// build_args returns the arguments for V compiler used to build the program.
pub fn (build Build) build_args() []string {
	mut vargs := []string{}
	vargs << build.vflags
	if build.os != '' {
		vargs << ['-os', build.os]
	}
	if build.arch != '' {
		vargs << ['-arch', build.arch]
	}
	if build.cc != '' {
		vargs << ['-cc', build.cc]
	}
	for cflag in build.cflags {
		vargs << ['-cflags', cflag]
	}
	for cflag in build.cflags {
		vargs << ['-cflags', cflag]
	}
	vargs << ['-o', build.artifact_name()]
	vargs << build.entrypoint
	return vargs
}

// build performs the program compilation by calling the V compiler with build arguments
// and returns the artifact path on success.
pub fn (build Build) build() !string {
	vargs := build.build_args()
	mut p := os.new_process(path_of_executable(build.v)!)
	p.set_args(vargs)
	p.set_work_folder(build.work_dir)
	p.set_environment(maps.merge(os.environ(), build.env))
	p.run()
	p.wait()
	if p.code != 0 {
		return error('build: v exited with non-zero code: ${p.code}')
	}
	return build.artifact_path()
}
