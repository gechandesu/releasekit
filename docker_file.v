module releasekit

// Dockerfile.new creates new Dockerfile builder.
pub fn Dockerfile.new() Dockerfile {
	return Dockerfile{
		data: []u8{cap: 4096}
	}
}

pub struct Dockerfile {
mut:
	data []u8
}

// pub struct KeyValue {
// 	key   string
// 	value string
// }

// pub struct DockerfileCopyOptions {}

// pub struct DockerfileAddOptions {}

// pub struct DockerfileHealthcheckOptions {}

// write writes the string s into internal buffer.
pub fn (mut f Dockerfile) write(s string) {
	unsafe { f.data.push_many(s.str, s.len) }
}

// write writes the string s followed by new line into internal buffer.
pub fn (mut f Dockerfile) writeln(s string) {
	unsafe { f.data.push_many(s.str, s.len) }
	f.data << `\n`
}

// write_from writes the FROM statement into builder.
pub fn (mut f Dockerfile) write_from(image string, alias ?string) {
	f.write('FROM ${image}')
	if alias != none {
		f.write(' AS ${alias}')
	}
	f.writeln('')
}

// write_run writes the formatted RUN statement into builder.
pub fn (mut f Dockerfile) write_run(cmds ...[]string) {
	if cmds.len == 0 {
		return
	}
	f.write('RUN ')
	mut line_len := 0
	for i := 0; i < cmds.len; i++ {
		line_len = 0
		if i != 0 {
			f.write('    && ')
		}
		for j := 0; j < cmds[i].len; j++ {
			line_len += cmds[i][j].len + 1
			f.write(cmds[i][j])
			if j + 1 != cmds[i].len && line_len <= 80 {
				f.write(' ')
			}
			if line_len >= 80 {
				line_len = 0
				if j + 1 != cmds[i].len {
					// Wrap long lines.
					f.write(' \\\n    ')
				}
			}
		}
		if i + 1 != cmds.len {
			f.writeln(r' \')
		} else {
			f.writeln('')
		}
	}
}

// pub fn (mut d Dockerfile) cmd(arg ...string) {}

// pub fn (mut d Dockerfile) label(pair ...KeyValue) {}

// pub fn (mut d Dockerfile) expose(portproto string) {}

pub fn (mut d Dockerfile) write_env(key string, value string) {
	d.writeln('ENV ${key}=${value}')
}

// pub fn (mut d Dockerfile) add(opts DockerfileAddOptions, src []string, dst string) {}

// pub fn (mut d Dockerfile) copy(opts DockerfileCopyOptions, src []string, dst string) {}

// pub fn (mut d Dockerfile) entrypoint(arg ...string) {}

// pub fn (mut d Dockerfile) volume(path ...string) {}

// pub fn (mut d Dockerfile) user(user string, group string) {}

// pub fn (mut d Dockerfile) workdir(path string) {}

// pub fn (mut d Dockerfile) arg(name string, default ?string) {}

// pub fn (mut d Dockerfile) stopsignal(signal string) {}

// pub fn (mut d Dockerfile) healthcheck(opts DockerfileHealthcheckOptions, cmd ...string) {}

// pub fn (mut d Dockerfile) shell(cmd ...string) {}

// str converts the builder data into (maybe) valid Dockerfile string.
pub fn (mut f Dockerfile) str() string {
	return f.data.bytestr()
}

// reset resets the builder internal buffer, so it can be reused.
pub fn (mut d Dockerfile) reset() {
	d.data = []u8{}
}
