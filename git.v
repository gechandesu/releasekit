module releasekit

// git_tag returns the Git tag with optional commit hash grabbed from `git describe HEAD`.
// Example output: `v1.0.0`, `v1.0.0-3-0328f0c8`.
pub fn git_tag() !string {
	if has_cmd('git') {
		r := run_capture_output('git', 'describe', 'HEAD')!
		if r.exit_code != 0 {
			return error('release_tag: failed: ${r.stderr}')
		}
		return r.stdout
	}
	return error('release_tag: failed: git command not found')
}

// git_hash returns the last Git commit hash returned by `git rev-parse HEAD` as string with optional `len`.
// Example: releasekit.git_hash() // 550ed8ab3f9212a406f94bca9647f1893467edab
// Example: releasekit.git_hash(8) // 550ed8ab
pub fn git_hash(len ?int) !string {
	if has_cmd('git') {
		r := run_capture_output('git', 'rev-parse', 'HEAD')!
		if r.exit_code != 0 {
			return error('release_hash: failed: ${r.stderr}')
		}
		return if len != none {
			r.stdout#[..len]
		} else {
			r.stdout
		}
	}
	return error('release_tag: failed: git command not found')
}
