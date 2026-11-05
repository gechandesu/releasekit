#!/usr/bin/env v

import arrays
import build
import os
import releasekit

const docker_base_image = 'debian:trixie'
const docker_image_name = 'v-cross-build'
const docker_file_path = 'Dockerfile'

const manifest = releasekit.manifest()

struct Build {
	releasekit.Build
	arch_alt string
	packages []string
}

const common = Build{
	name:    manifest.name
	version: manifest.version
	vflags:  ['-prod']
	cflags:  ['-static', '-s']
}

const targets = {
	'linux-amd64':   Build{
		...common
		os:   'linux'
		arch: 'amd64'
	}
	'linux-arm64':   Build{
		...common
		os:   'linux'
		arch: 'arm64'

		packages: ['libbsd-dev'] // not needed, added for demonstration only
	}
	'linux-arm32':   Build{
		...common
		os:   'linux'
		arch: 'arm32'

		arch_alt: 'armhf'
	}
	'linux-riscv64': Build{
		...common
		os:   'linux'
		arch: 'riscv64'
	}
	'windows-amd64': Build{
		...common
		os:   'windows'
		arch: 'amd64'
	}
}

fn main() {
	mut ctx := build.context(default: 'build')

	ctx.artifact(
		name: docker_file_path
		help: 'Make Dockerfile for cross-compilation'
		run:  fn (t build.Task) ! {
			content := build_dockerfile(targets.values())
			os.write_file(t.name, content)!
		}
	)

	for target, _ in targets {
		ctx.task(
			name:    'docker-image-${target}'
			help:    'Build Docker image with V cross-compiling environment for ${target.to_upper()}'
			depends: ['Dockerfile']

			run: fn [target] (_ build.Task) ! {
				releasekit.run_or_fail('docker', 'build', '--tag',
					docker_image_name + ':' + target, '--target', target, '--file',
					docker_file_path, '.')!
			}
		)
	}

	for target, build_config in targets {
		ctx.task(
			name:    'build-${target}'
			help:    'Cross-compile program for ${target.to_upper()}'
			depends: ['docker-image-${target}']

			run: fn [target, build_config] (_ build.Task) ! {
				mut args := ['run', '--rm', '--volume', build_config.work_dir + ':/app', '--workdir',
					'/app', '--user', '1000:1000', docker_image_name + ':' + target]
				args << 'v'
				args << build_config.build_args()
				releasekit.run_or_fail('docker', ...args)!

				artifact_checksum := build_config.artifact_path() + '.sha256'
				oldwd := os.getwd()
				os.chdir(build_config.output_dir)!
				sum := releasekit.checksum(build_config.artifact_name(), .sha256)!
				os.write_file(artifact_checksum, sum)!
				os.chdir(oldwd)!
			}
		)
	}

	ctx.task(
		name:    'build'
		help:    'Compile program for all targets'
		run:     |_| true
		depends: targets.keys().map(|t| 'build-' + t)
	)

	ctx.run()
}

fn build_dockerfile(targets []Build) string {
	mut f := releasekit.Dockerfile.new()
	f.write_from(docker_base_image, 'base')
	f.write_env('VMODULES', '/tmp/vmodules')
	f.write_env('VCACHE', '/tmp/vcache')
	f.write_env('DEBIAN_FRONTEND', 'noninteractive')
	f.write_run(...[
		['apt-get', 'update'],
		['apt-get', 'install', '--yes', '--no-install-recommends', '--no-install-suggests',
			'build-essential', 'ca-certificates', 'git'],
		['apt-get', 'clean'],
	])
	f.write_run(...[
		['git', 'clone', '--depth=1', 'https://github.com/vlang/v', '/opt/v'],
		['make', '-C', '/opt/v'],
		['/opt/v/v', 'symlink'],
		['v', 'version'],
		['rm', '-rf', '/tmp/*'],
	])
	f.writeln('')
	for i, target in targets {
		deb_arch := if target.arch_alt != '' { target.arch_alt } else { target.arch }

		f.write_from('base', '${target.os}-${target.arch}')
		mut packages := []string{}
		if deb_arch != 'amd64' {
			packages << 'crossbuild-essential-${deb_arch}'
		}
		if target.os == 'windows' && target.arch == 'amd64' {
			packages << 'gcc-mingw-w64-x86-64'
		}
		for package in target.packages {
			if deb_arch == 'amd64' {
				packages << package
			} else {
				packages << '${package}:${deb_arch}'
			}
		}
		mut commands := [][]string{}
		if target.arch != 'amd64' {
			commands << ['dpkg', '--add-architecture', deb_arch]
		}
		if packages.len > 0 {
			commands << ['apt-get', 'update']
			commands << arrays.append([
				'apt-get',
				'install',
				'--yes',
				'--no-install-recommends',
				'--no-install-suggests',
			], packages)
			commands << ['apt-get', 'clean']
		}
		f.write_run(...commands)
		if i < targets.len - 1 {
			f.writeln('')
		}
	}
	return f.str()
}
