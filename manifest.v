module releasekit

import v.vmod
import os

// manifest parses and returns the parsed content of the nearest v.mod file or *file* if set.
pub fn manifest(file ?string) vmod.Manifest {
	mut file_path := ''

	if file == none {
		mut vmod_cache := vmod.get_cache()
		file_and_folder := vmod_cache.get_by_folder(os.getwd())
		file_path = file_and_folder.vmod_file
	} else {
		file_path = file
	}

	file_path = os.real_path(file_path)

	return vmod.from_file(file_path) or { vmod.Manifest{} }
}
