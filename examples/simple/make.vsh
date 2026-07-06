#!/usr/bin/env v

import build
import releasekit as rk

const manifest = rk.manifest()

const config = rk.Build{
	name:    manifest.name
	version: manifest.version
	vflags:  ['-prod']
	cflags:  ['-static', '-s']
}

const binary = config.artifact_name()
const zip_archive = binary.trim_right('.exe') + '.zip'

mut ctx := build.context(default: 'release')

ctx.artifact(
	name: binary
	help: 'Build program'
	run:  |_| config.build()!
)

ctx.artifact(
	name:    zip_archive
	help:    'Pack binary into ZIP archive'
	depends: [binary]

	run: fn (_ build.Task) ! {
		rk.ensure_cmd('zip')
		rk.run_or_fail('zip', '-q', zip_archive, binary)!
	}
)

ctx.task(
	name:    'release'
	help:    'Make release build'
	run:     |_| false
	depends: [zip_archive]
)

ctx.run()
